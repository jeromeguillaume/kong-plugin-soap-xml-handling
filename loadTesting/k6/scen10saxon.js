import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='35.241.175.116';

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
        { duration: '30s', target: 6 },
        { duration: '30s', target: 12 },
        { duration: '30s', target: 20 },
        { duration: '900s', target: 20 },
      ],
      gracefulRampDown: '5s',
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
      <site>London</site>
      <site>Bangalore</site>
      <site>Singapore</site>
      <site>Shangai</site>
      <site>Japan</site>
   </offices>
   <products>
      <product name="Kong konnect">
         <version>2024</version>
         <saas>true</saas>
      </product>
      <product name="Kong AI Gateway">
         <version>3.8</version>
         <saas>false</saas>
      </product>
      <product name="Kong Ingress Controller">
         <version>3.3</version>
         <saas>false</saas>
      </product>
      <product name="Kong Mesh">
         <version>2.8</version>
         <saas>false</saas>
      </product>
      <product name="Insomnia">
         <version>10</version>
         <saas>false</saas>
      </product>
   </products>
</root>`;
    
  
  const result = http.post('https://'+host+'/scen10saxon/anything', XMLRequest, {
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
}