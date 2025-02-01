import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='35.241.175.116';


export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    scen3ok: {
      exec: 'scen3ok',
      
      /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 5,
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
    scen3ko: {
      exec: 'scen3ko',
      
      /*executor: 'per-vu-iterations',
      vus: 1,
      iterations: 5,
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

export function scen3ok () {
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
  
  const result = http.post('https://'+host+'/scen3', calcReq, {
    headers: { 
        'Content-Type': 'text/xml; charset=utf-8',
      },
  });

  check(result, {
    'scen3ok - http response status code is 200': result.status === 200,
    'scen3ok - Content-Type': result.headers['Content-Type'] === 'text/xml;charset=utf-8',
    "scen3ok - calculator Result": result =>
      result.body.includes("<AddResult>12</AddResult>"),
  });
}

export function scen3ko () {
  const calcReq = 
  `<?xml version=\"1.0\" encoding=\"utf-8\"?>
  <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
    <soap:Body>
      <Add_DOES_NOT_EXIST xmlns=\"http://tempuri.org/\">
        <intA>5</intA>
        <intB>7</intB>
      </Add_DOES_NOT_EXIST>
    </soap:Body>
  </soap:Envelope>`;
  
  const result = http.post('https://'+host+'/scen3', calcReq, {
    headers: { 
        'Content-Type': 'text/xml; charset=utf-8',
      },
  });

  const expectedError = 
`<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>Request - XSD validation failed</faultstring>
      <detail>Error Node: Add_DOES_NOT_EXIST, Error code: 1845, Line: 4, Message: Element '{http://tempuri.org/}Add_DOES_NOT_EXIST': No matching global declaration available for the validation root.</detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
`;

  check(result, {
    'scen3ko - http response status code is 500': result.status === 500,
    'scen3ko - Content-Type': result.headers['Content-Type'] === 'text/xml; charset=utf-8',
  });

  check(result.body, { 'scen3ko - calculator Failed': result.body == expectedError });
  
}