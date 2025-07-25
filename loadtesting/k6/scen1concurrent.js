import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='35.237.168.227';


export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {    
    scen1ok: {
      exec: 'scen1ok',
      
      /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '1s'*/
      
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
    scen1ko: {
      exec: 'scen1ko',
      
      /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '1s'*/
      
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

export function scen1ok () {
  const calcReq = 
  `<?xml version=\"1.0\" encoding=\"utf-8\"?>
  <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
    <soap:Body>
      <Add xmlns=\"http://tempuri.org/\">
        <intA>5</intA>
        <intB>7</intB>
      </Add>
    </soap:Body>
  </soap:Envelope>`;
  
  const result = http.post('https://'+host+'/scen1', calcReq, {
    headers: { 
        'Content-Type': 'text/xml; charset=utf-8',
      },
  });

  check(result, {
    'scen1ok - http response status code is 200': result.status === 200,
    'scen1ok - Content-Type': result.headers['Content-Type'] === 'text/xml;charset=utf-8',
    "scen1ok - calculator Result": result =>
      result.body.includes("<AddResult>12</AddResult>"),
  }); 
}

export function scen1ko () {
  const calcReq = 
  `<?xml version=\"1.0\" encoding=\"utf-8\"?>
  <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
    <soap:Body>
      <Add xmlns=\"http://tempuri.org/\">
        <intA>5</intA>
        <intB>7</intB>
      </Add>
    </soap:Body>
  </soap:Envelope>`;
  
  const result = http.post('https://'+host+'/scen1invalidwsdl', calcReq, {
    headers: { 
        'Content-Type': 'text/xml; charset=utf-8',
      },
  });

  check(result, {
    'scen1ko - http response status code is 500': result.status === 500,
    'scen1ko - Content-Type': result.headers['Content-Type'] === 'text/xml; charset=utf-8',
  });

  console.log('result.body:' + result.body);
  const expectedError = 
`<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request - XSD validation failed</faultstring>
      <detail>Unable to find a suitable Schema to validate the SOAP/XML</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
`;

  check(result.body, { 'scen1ko - calculator Failed': result.body == expectedError });
}