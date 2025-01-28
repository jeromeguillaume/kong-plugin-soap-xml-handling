import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='35.241.175.116';


export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    scen4: {
      exec: 'scen4',
      
      /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '1s'*/
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '30s', target: 6 },
        { duration: '30s', target: 12 },
        { duration: '30s', target: 25 },
        { duration: '900s', target: 25 },
      ],
      gracefulRampDown: '5s',
    },
  },
};

export function scen4 () {
  const calcReq = 
  `<?xml version=\"1.0\" encoding=\"utf-8\"?>
  <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
    <soap:Body>
      <Subtract xmlns=\"http://tempuri.org/\">
        <intA>5</intA>
        <intB>7</intB>
      </Subtract>
    </soap:Body>
  </soap:Envelope>`;
  
  const result = http.post('https://'+host+'/scen4', calcReq, {
    headers: { 
        'Content-Type': 'text/xml; charset=utf-8',
      },
  });

  check(result, {
    'http response status code is 200': result.status === 200,
    'Content-Type': result.headers['Content-Type'] === 'text/xml;charset=utf-8',
    "calculator Result": result =>
      result.body.includes("<AddResult>12</AddResult>"),
  });

  sleep(0.04)
  
}