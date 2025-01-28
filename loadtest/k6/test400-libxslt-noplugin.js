import http from 'k6/http';
import { check } from 'k6';

const host='kong-proxy.kong:8000';
//const host='34.140.107.193';


export const options = {
  scenarios: {
    scenOk: {
      exec: 'scenOk',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '30s', target: 50 },
        { duration: '30s', target: 100 },
        { duration: '300s', target: 400 },
      ],
      gracefulRampDown: '10s',
    },
  },
  //cloud: {
  //  projectID: 3741989,
  //  name: 'Test 50'
  //}
};

export function scenOk () {
  const calcAdd = 
  `<?xml version="1.0" encoding="utf-8"?>
  <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
      <Add xmlns="http://tempuri.org/">
        <intA>100</intA>
        <intB>200</intB>
      </Add>
    </soap:Body>
  </soap:Envelope>`;
  
  const result = http.post('http://'+host+'/noPlugink8sCalculator', calcAdd, {
    headers: { 'Content-Type': 'text/xml; charset=utf-8' },
  });

  check(result, {
    'http response status code is 200': result.status === 200,
    'Content-Type': result.headers['Content-Type'] === 'text/xml;charset=utf-8',
    "calculator Result": result =>
      result.body.includes("<AddResult>300</AddResult>"),
  });
}