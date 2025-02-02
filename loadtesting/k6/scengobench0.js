import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='104.155.14.209';


export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    scengobench0: {
      exec: 'scengobench0',
      
      /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '1s'*/
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '30s', target: 6 },
        { duration: '30s', target: 12 },
        { duration: '30s', target: 100 },
        { duration: '900s', target: 100 },
      ],
      gracefulRampDown: '5s',
    },
  },
};

export function scengobench0 () {
  const paramJSON = {
  val1: 'value1-value1-value1-value1-value1-value1-value1-value1-value1-value1-value1',
  val2: 'value2-value2-value2-value2-value2-value2-value2-value2-value2-value2-value2',
  val3: 'value3-value3-value3-value3-value3-value3-value3-value3-value3-value3-value3',
  val4: 'value4-value4-value4-value4-value4-value4-value4-value4-value4-value4-value4'
  };
  let paramString = "p1=" + JSON.stringify(paramJSON);
  
  const result = http.get('https://'+host+'/scengobench0/size/350B', paramString, {
    headers: { 
        'Content-Type': 'text/plain',
      },
  });

  check(result, {
    'http response status code is 200': result.status === 200,
    'Content-Type': result.headers['Content-Type'] === 'text/plain; charset=utf-8',
  });
}