import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='35.241.175.116';

const calcSleep = 0.005;

export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    scenOk: {
      exec: 'scen10saxon',
      
      /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '1s',*/
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
  },
};

export function scen10saxon () {
  const XMLRequest = 
`<?xml version="1.0" encoding="UTF-8"?>
<root>
   <companyName>KongHQ</companyName>
   <city>SAN FRANCISCO</city>
   <state>CA</state>
   <country>USA</country>
   <offices>
      <site>San Francisco (HQ)</site>
      <site>Chicago</site>
      <site>Bangalore</site>
      <site>Singapore</site>
      <site>Shangai</site>
   </offices>
   <products/>
</root>`;
    
  
  const result = http.post('https://'+host+'/scen10saxon/XXXX_______anything', XMLRequest, {
    headers: { 
      'Content-Type': 'text/xml; charset=utf-8',
    },
  });
  check(result, {
    'http response status code is 200': result.status === 200,
    'Content-Type': result.headers['Content-Type'] === 'text/xml; charset=utf-8',
  });

  if (result.status === 200) {
    check(result, {
    "XML Result": result =>
      !(result.body === undefined) && result.body.includes(XMLRequest),
   });   
  }
  sleep (calcSleep);
}