#!/usr/bin/env python3

import requests
import subprocess
import time
import json
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DockerAutoscaler:
    def __init__(self):
        self.prometheus_url = "http://localhost:9090"
        self.service_name = "service-a"
        self.min_replicas = 1
        self.max_replicas = 5
        self.cpu_threshold = 70
        self.memory_threshold = 80
        self.scale_up_cooldown = 60
        self.scale_down_cooldown = 300
        self.last_scale_time = 0

    def get_metric(self, query):
        try:
            response = requests.get(f"{self.prometheus_url}/api/v1/query", 
                                  params={'query': query}, timeout=10)
            data = response.json()
            if data['status'] == 'success' and data['data']['result']:
                return float(data['data']['result'][0]['value'][1])
        except Exception as e:
            logger.error(f"Error getting metric: {e}")
        return None

    def get_current_replicas(self):
        try:
            result = subprocess.run(['docker', 'service', 'ls', '--format', 'json'], 
                                  capture_output=True, text=True)
            services = [json.loads(line) for line in result.stdout.strip().split('\n') if line]
            for service in services:
                if self.service_name in service['Name']:
                    return int(service['Replicas'].split('/')[1])
        except Exception as e:
            logger.error(f"Error getting replicas: {e}")
        return 1

    def scale_service(self, replicas):
        try:
            service_name = f"docker_{self.service_name}"
            subprocess.run(['docker', 'service', 'scale', f"{service_name}={replicas}"], 
                         check=True)
            logger.info(f"Scaled {service_name} to {replicas} replicas")
            self.last_scale_time = time.time()
            return True
        except Exception as e:
            logger.error(f"Error scaling service: {e}")
            return False

    def should_scale_up(self, cpu_usage, memory_usage, current_replicas):
        if current_replicas >= self.max_replicas:
            return False
        if time.time() - self.last_scale_time < self.scale_up_cooldown:
            return False
        return cpu_usage > self.cpu_threshold or memory_usage > self.memory_threshold

    def should_scale_down(self, cpu_usage, memory_usage, current_replicas):
        if current_replicas <= self.min_replicas:
            return False
        if time.time() - self.last_scale_time < self.scale_down_cooldown:
            return False
        return cpu_usage < self.cpu_threshold * 0.5 and memory_usage < self.memory_threshold * 0.5

    def run(self):
        logger.info("Starting Docker Autoscaler...")
        
        while True:
            try:
                # Get metrics
                cpu_query = 'rate(container_cpu_usage_seconds_total{name=~".*service-a.*"}[5m]) * 100'
                memory_query = 'container_memory_usage_bytes{name=~".*service-a.*"} / container_spec_memory_limit_bytes{name=~".*service-a.*"} * 100'
                
                cpu_usage = self.get_metric(cpu_query) or 0
                memory_usage = self.get_metric(memory_query) or 0
                current_replicas = self.get_current_replicas()
                
                logger.info(f"CPU: {cpu_usage:.1f}%, Memory: {memory_usage:.1f}%, Replicas: {current_replicas}")
                
                # Scale decision
                if self.should_scale_up(cpu_usage, memory_usage, current_replicas):
                    new_replicas = min(current_replicas + 1, self.max_replicas)
                    logger.info(f"Scaling up to {new_replicas} replicas")
                    self.scale_service(new_replicas)
                elif self.should_scale_down(cpu_usage, memory_usage, current_replicas):
                    new_replicas = max(current_replicas - 1, self.min_replicas)
                    logger.info(f"Scaling down to {new_replicas} replicas")
                    self.scale_service(new_replicas)
                
            except Exception as e:
                logger.error(f"Error in autoscaler loop: {e}")
            
            time.sleep(30)

if __name__ == "__main__":
    autoscaler = DockerAutoscaler()
    autoscaler.run()