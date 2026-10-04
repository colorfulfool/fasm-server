import http from "k6/http";
import { check, sleep } from "k6";

// Test configuration
export const options = {
  thresholds: {
    // Assert that 99% of requests finish within 3000ms.
    http_req_duration: ["p(99) < 200"],
  },
  iterations: 100
};

export default function() {
  let res = http.get(`http://${__ENV.HOST}:6969`);
  check(res, { "status was 200": (r) => r.status == 200 });
  sleep(1);
}
