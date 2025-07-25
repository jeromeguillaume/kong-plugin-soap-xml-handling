import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='35.237.168.227';


export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    scenhttpbin1: {
      exec: 'scenhttpbin1',
      
     /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '1s'*/
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '30s', target: 6 },
        { duration: '30s', target: 12 },
        { duration: '30s', target: 300 },
        { duration: '900s', target: 300 },
      ],
      gracefulRampDown: '5s',
    },
  },
};

export function scenhttpbin1 () {
  const bodyJSON = {
  val1: 'value1-value1-value1-value1-value1-value1-value1-value1-value1-value1-value1',
  val2: 'value2-value2-value2-value2-value2-value2-value2-value2-value2-value2-value2',
  val3: 'value3-value3-value3-value3-value3-value3-value3-value3-value3-value3-value3',
  val4: 'value4-value4-value4-value4-value4-value4-value4-value4-value4-value4-value4'
  };
  let bodyString = JSON.stringify(bodyJSON);
  
  const result = http.post('https://'+host+'/scenhttpbin1/anything', bodyString, {
    headers: { 
        'Content-Type': 'application/json',
      },
  });

  
  check(result, {
    'http response status code is 200': result.status === 200,
    'Content-Type': result.headers['Content-Type'] === 'application/json',
    'JSON object': result.headers['Content-Type'] === 'application/json',
  });

  if (result.status === 200) {
    const responseBody = JSON.parse(result.body);
    const httpbinJSON = responseBody.json
    check(httpbinJSON, { 'Response contains JSON property': JSON.stringify(httpbinJSON) == bodyString });
  }
}