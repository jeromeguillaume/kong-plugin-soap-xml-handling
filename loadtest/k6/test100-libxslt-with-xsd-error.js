import http from 'k6/http';
import { check } from 'k6';

const host='kong-proxy.kong:8000';
//const host='34.140.107.193';

export const options = {
  scenarios: {
    scenKo: {
      executor: 'constant-vus',
      exec: 'scenKo',
      vus: 50,
      duration: '120s',
      gracefulStop: '5s',
    },
    scenOk: {
      executor: 'constant-vus',
      exec: 'scenOk',
      vus: 50,
      duration: '100s',
      gracefulStop: '5s',
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

  
  const result = http.post('http://'+host+'/k8sCalculator', calcAdd, {
    headers: { 'Content-Type': 'text/xml; charset=utf-8' },
  });

  check(result, {
    'http response status code is 200': result.status === 200,
    'Content-Type': result.headers['Content-Type'] === 'text/xml;charset=utf-8',
    "calculator Result": result =>
      result.body.includes("<AddResult>300</AddResult>"),
  });
}

export function scenKo () {
  const calcAdd = 
  `<?xml version="1.0" encoding="utf-8"?>
  <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
      <Add2 xmlns="http://tempuri.org/">
        <intA>100</intA>
        <intB>200</intB>
      </Add2>
    </soap:Body>
  </soap:Envelope>`;

  const result = http.post('http://'+host+'/k8sCalculator', calcAdd, {
    headers: { 'Content-Type': 'text/xml; charset=utf-8' },
  });

  console.log("body:" + result.body);
  check(result, {
    'http response status code is 500': result.status === 500,
    'Content-Type': result.headers['Content-Type'] === 'text/xml; charset=utf-8',
    "calculator Failed - Error Node: Add2": result =>
      result.body.includes("<detail>Error Node: Add2, Error code: 1845, Line: 4, Message: Element '{http://tempuri.org/}Add2'"),
  });
}