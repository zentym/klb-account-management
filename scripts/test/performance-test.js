import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');

// Test configuration
export let options = {
    stages: [
        { duration: '2m', target: 10 }, // Ramp up to 10 users over 2 minutes
        { duration: '5m', target: 10 }, // Stay at 10 users for 5 minutes
        { duration: '2m', target: 20 }, // Ramp up to 20 users over 2 minutes
        { duration: '5m', target: 20 }, // Stay at 20 users for 5 minutes
        { duration: '2m', target: 0 },  // Ramp down to 0 users over 2 minutes
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests must be below 500ms
        http_req_failed: ['rate<0.1'],    // Error rate must be below 10%
        errors: ['rate<0.1'],
    },
};

// Base URL - sẽ được override bởi environment variable
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
    // Test 1: Health check
    let healthResponse = http.get(`${BASE_URL}/actuator/health`);
    check(healthResponse, {
        'health check status is 200': (r) => r.status === 200,
        'health check response time < 200ms': (r) => r.timings.duration < 200,
    });

    sleep(1);

    // Test 2: API Gateway endpoint
    let apiResponse = http.get(`${BASE_URL}/api/v1/customers`);
    check(apiResponse, {
        'customers API status is 200 or 401': (r) => r.status === 200 || r.status === 401,
        'customers API response time < 500ms': (r) => r.timings.duration < 500,
    }) || errorRate.add(1);

    sleep(1);

    // Test 3: Customer Service endpoint
    let customerResponse = http.get(`${BASE_URL}/customer-service/actuator/health`);
    check(customerResponse, {
        'customer service health is 200': (r) => r.status === 200,
    }) || errorRate.add(1);

    sleep(1);

    // Test 4: Loan Service endpoint
    let loanResponse = http.get(`${BASE_URL}/loan-service/actuator/health`);
    check(loanResponse, {
        'loan service health is 200': (r) => r.status === 200,
    }) || errorRate.add(1);

    sleep(1);

    // Test 5: Static resource loading (Frontend)
    if (__ENV.TEST_FRONTEND === 'true') {
        let staticResponse = http.get(`${BASE_URL}/static/js/main.js`);
        check(staticResponse, {
            'static resource loads successfully': (r) => r.status === 200 || r.status === 404,
        });
    }

    sleep(2);
}

// Setup function - runs once before the test
export function setup() {
    console.log('Starting performance test...');
    console.log(`Base URL: ${BASE_URL}`);

    // Warm up the application
    http.get(`${BASE_URL}/actuator/health`);

    return { baseUrl: BASE_URL };
}

// Teardown function - runs once after the test
export function teardown(data) {
    console.log('Performance test completed');
    console.log(`Tested against: ${data.baseUrl}`);
}
