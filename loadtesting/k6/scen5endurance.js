import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='35.241.175.116';

export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    scenOk: {
      exec: 'scen5endurance',
      
      /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '1s',*/
      
      executor: 'ramping-vus',
      startvus: 20,
      stages: [
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '5s',
    },
  },
};

export function scen5endurance () {
  const calcReq = 
  `<?xml version=\"1.0\" encoding=\"utf-8\"?>
  <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
    <soap:Body>
      <Subtract xmlns=\"http://tempuri.org/\">
        <intA>5</intA>
        <intB>0</intB>
      </Subtract>
    </soap:Body>
  </soap:Envelope>`;
  
  const result = http.post('https://'+host+'/scen5endurance', calcReq, {
    headers: { 
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': 'http://tempuri.org/Add'
      },
  });

  check(result, {
    'http response status code is 200': result.status === 200,
    'Content-Type': result.headers['Content-Type'] === 'text/xml;charset=utf-8',
    'X-Soap-Region': result.headers['X-Soap-Region'] === 'soap2',
    "calculator Result": result =>
      //result.body.includes("<AddResult>15</AddResult>"),
      result.body.includes("<KongResult>15</KongResult>"),
  });

  sleep (0.025);
}