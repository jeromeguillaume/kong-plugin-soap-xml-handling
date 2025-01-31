import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='35.241.175.116';

export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    scenOk: {
      exec: 'scen9saxon',
      
      /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '1s',*/
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '30s', target: 6 },
        { duration: '30s', target: 12 },
        { duration: '30s', target: 20 },
        { duration: '900s', target: 20 },
      ],
      gracefulRampDown: '5s',
    },
  },
};

export function scen9saxon () {
  const bodyJSON = {
    operation: 'Add',
	  intA: 50,
	  intB: 10
  };
  let bodyString = JSON.stringify(bodyJSON);
    
  
  const result = http.post('https://'+host+'/scen9saxon', bodyString, {
    headers: { 
      'Content-Type': 'application/json',
    },
  });

  check(result, {
    'http response status code is 200': result.status === 200,
    'Content-Type': result.headers['Content-Type'] === 'application/json',
  });
  const expectedBody = {
      result: 60
    };

    

  if (result.status === 200) {
    const responseBody = JSON.parse(result.body);
    check(responseBody, { 'Response contains JSON property': JSON.stringify(responseBody) == JSON.stringify(expectedBody) });
  }
}