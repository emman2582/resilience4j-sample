/**
 * Lambda Adapter for Service A Spring Boot Application
 */

const { spawn } = require('child_process');
const axios = require('axios');

let springBootProcess = null;
let isReady = false;

async function startSpringBoot() {
    if (springBootProcess) return;
    
    console.log('Starting Spring Boot application...');
    springBootProcess = spawn('java', [
        '-jar', '/app/service-a.jar',
        '--server.port=8080'
    ], { stdio: 'pipe' });

    for (let i = 0; i < 30; i++) {
        try {
            await axios.get('http://localhost:8080/actuator/health');
            isReady = true;
            console.log('Spring Boot application ready');
            return;
        } catch (error) {
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
    }
    throw new Error('Spring Boot application failed to start');
}

function eventToHttpRequest(event) {
    const { httpMethod, path, queryStringParameters, headers, body } = event;
    
    return {
        method: httpMethod || 'GET',
        url: `http://localhost:8080${path}`,
        params: queryStringParameters || {},
        headers: headers || {},
        data: body && typeof body === 'string' ? JSON.parse(body) : body
    };
}

exports.handler = async (event, context) => {
    try {
        if (!isReady) {
            await startSpringBoot();
        }

        const httpRequest = eventToHttpRequest(event);
        const response = await axios(httpRequest);
        
        return {
            statusCode: response.status,
            headers: response.headers,
            body: JSON.stringify(response.data)
        };
    } catch (error) {
        console.error('Lambda adapter error:', error);
        
        return {
            statusCode: error.response?.status || 500,
            body: JSON.stringify({
                error: 'Lambda adapter error',
                message: error.message
            })
        };
    }
};