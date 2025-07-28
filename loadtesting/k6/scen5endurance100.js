import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='35.237.168.227';

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
const calcRes = "<AddResponse><KongResult>18</KongResult></AddResponse>";

//const calcSleep = 0.190;  // { duration: '1m', target: 10 }, { duration: '24h', target: 20 }, => 3050 req/s
//const calcSleep = 0.350; // // { duration: '1m', target: 10 }, { duration: '24h', target: 20 }, => 2800 req/s

const calcSleep = 0.650;

export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    scen5endurance_0001: {
      exec: 'scen5endurance_0001',
      
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
    scen5endurance_0002: {
      exec: 'scen5endurance_0002',
      
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
    scen5endurance_0003: {
      exec: 'scen5endurance_0003',
      
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
    scen5endurance_0004: {
      exec: 'scen5endurance_0004',
      
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
    scen5endurance_0005: {
      exec: 'scen5endurance_0005',
      
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
    scen5endurance_0006: {
      exec: 'scen5endurance_0006',
      
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
    scen5endurance_0007: {
      exec: 'scen5endurance_0007',
      
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
    scen5endurance_0008: {
      exec: 'scen5endurance_0008',
      
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
    scen5endurance_0009: {
      exec: 'scen5endurance_0009',
      
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
    scen5endurance_0010: {
      exec: 'scen5endurance_0010',
      
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
    scen5endurance_0011: {
      exec: 'scen5endurance_0011',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0012: {
      exec: 'scen5endurance_0012',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0013: {
      exec: 'scen5endurance_0013',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0014: {
      exec: 'scen5endurance_0014',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0015: {
      exec: 'scen5endurance_0015',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0016: {
      exec: 'scen5endurance_0016',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0017: {
      exec: 'scen5endurance_0017',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0018: {
      exec: 'scen5endurance_0018',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0019: {
      exec: 'scen5endurance_0019',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0021: {
      exec: 'scen5endurance_0021',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0022: {
      exec: 'scen5endurance_0022',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0023: {
      exec: 'scen5endurance_0023',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0024: {
      exec: 'scen5endurance_0024',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0025: {
      exec: 'scen5endurance_0025',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0026: {
      exec: 'scen5endurance_0026',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0027: {
      exec: 'scen5endurance_0027',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0028: {
      exec: 'scen5endurance_0028',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0029: {
      exec: 'scen5endurance_0029',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0030: {
      exec: 'scen5endurance_0030',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0031: {
      exec: 'scen5endurance_0031',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0032: {
      exec: 'scen5endurance_0032',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0033: {
      exec: 'scen5endurance_0033',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0034: {
      exec: 'scen5endurance_0034',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0035: {
      exec: 'scen5endurance_0035',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0036: {
      exec: 'scen5endurance_0036',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0037: {
      exec: 'scen5endurance_0037',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0038: {
      exec: 'scen5endurance_0038',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0039: {
      exec: 'scen5endurance_0039',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0040: {
      exec: 'scen5endurance_0040',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0041: {
      exec: 'scen5endurance_0041',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0042: {
      exec: 'scen5endurance_0042',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0043: {
      exec: 'scen5endurance_0043',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0044: {
      exec: 'scen5endurance_0044',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0045: {
      exec: 'scen5endurance_0045',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0046: {
      exec: 'scen5endurance_0046',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0047: {
      exec: 'scen5endurance_0047',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0048: {
      exec: 'scen5endurance_0048',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0049: {
      exec: 'scen5endurance_0049',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0050: {
      exec: 'scen5endurance_0050',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0051: {
      exec: 'scen5endurance_0051',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0052: {
      exec: 'scen5endurance_0052',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0053: {
      exec: 'scen5endurance_0053',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0054: {
      exec: 'scen5endurance_0054',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0055: {
      exec: 'scen5endurance_0055',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0056: {
      exec: 'scen5endurance_0056',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0057: {
      exec: 'scen5endurance_0057',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0058: {
      exec: 'scen5endurance_0058',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0059: {
      exec: 'scen5endurance_0059',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0060: {
      exec: 'scen5endurance_0060',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0061: {
      exec: 'scen5endurance_0061',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0062: {
      exec: 'scen5endurance_0062',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0063: {
      exec: 'scen5endurance_0063',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0064: {
      exec: 'scen5endurance_0064',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0065: {
      exec: 'scen5endurance_0065',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0066: {
      exec: 'scen5endurance_0066',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0067: {
      exec: 'scen5endurance_0067',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0068: {
      exec: 'scen5endurance_0068',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0069: {
      exec: 'scen5endurance_0069',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0070: {
      exec: 'scen5endurance_0070',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0071: {
      exec: 'scen5endurance_0071',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0072: {
      exec: 'scen5endurance_0072',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0073: {
      exec: 'scen5endurance_0073',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0074: {
      exec: 'scen5endurance_0074',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0075: {
      exec: 'scen5endurance_0075',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0076: {
      exec: 'scen5endurance_0076',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0077: {
      exec: 'scen5endurance_0077',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0078: {
      exec: 'scen5endurance_0078',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0079: {
      exec: 'scen5endurance_0079',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0080: {
      exec: 'scen5endurance_0080',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0081: {
      exec: 'scen5endurance_0081',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0082: {
      exec: 'scen5endurance_0082',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0083: {
      exec: 'scen5endurance_0083',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0084: {
      exec: 'scen5endurance_0084',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0085: {
      exec: 'scen5endurance_0085',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0086: {
      exec: 'scen5endurance_0086',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0087: {
      exec: 'scen5endurance_0087',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0088: {
      exec: 'scen5endurance_0088',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0089: {
      exec: 'scen5endurance_0089',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0090: {
      exec: 'scen5endurance_0090',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0091: {
      exec: 'scen5endurance_0091',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0092: {
      exec: 'scen5endurance_0092',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0093: {
      exec: 'scen5endurance_0093',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0094: {
      exec: 'scen5endurance_0094',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0095: {
      exec: 'scen5endurance_0095',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0096: {
      exec: 'scen5endurance_0096',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0097: {
      exec: 'scen5endurance_0097',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0098: {
      exec: 'scen5endurance_0098',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0099: {
      exec: 'scen5endurance_0099',
            
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen5endurance_0100: {
      exec: 'scen5endurance_0100',
            
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

export function scen5endurance_0001 () {  
  
  const result = http.post('https://'+host+'/scen5_0001', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0002 () {  
  
  const result = http.post('https://'+host+'/scen5_0002', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0003 () {  
  
  const result = http.post('https://'+host+'/scen5_0003', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0004 () {  
  
  const result = http.post('https://'+host+'/scen5_0004', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0005 () {  
  
  const result = http.post('https://'+host+'/scen5_0005', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0006 () {  
  
  const result = http.post('https://'+host+'/scen5_0006', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0007 () {  
  
  const result = http.post('https://'+host+'/scen5_0007', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0008 () {  
  
  const result = http.post('https://'+host+'/scen5_0008', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0009 () {  
  
  const result = http.post('https://'+host+'/scen5_0009', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0010 () {  
  
  const result = http.post('https://'+host+'/scen5_0010', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0011 () {  
  
  const result = http.post('https://'+host+'/scen5_0011', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0012 () {  
  
  const result = http.post('https://'+host+'/scen5_0012', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0013 () {  
  
  const result = http.post('https://'+host+'/scen5_0013', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0014 () {  
  
  const result = http.post('https://'+host+'/scen5_0014', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0015 () {  
  
  const result = http.post('https://'+host+'/scen5_0015', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0016 () {  
  
  const result = http.post('https://'+host+'/scen5_0016', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0017 () {  
  
  const result = http.post('https://'+host+'/scen5_0017', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0018 () {  
  
  const result = http.post('https://'+host+'/scen5_0018', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0019 () {  
  
  const result = http.post('https://'+host+'/scen5_0019', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0020 () {  
  
  const result = http.post('https://'+host+'/scen5_0020', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0021 () {  
  
  const result = http.post('https://'+host+'/scen5_0021', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0022 () {  
  
  const result = http.post('https://'+host+'/scen5_0022', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0023 () {  
  
  const result = http.post('https://'+host+'/scen5_0023', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0024 () {  
  
  const result = http.post('https://'+host+'/scen5_0024', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0025 () {  
  
  const result = http.post('https://'+host+'/scen5_0025', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0026 () {  
  
  const result = http.post('https://'+host+'/scen5_0026', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0027 () {  
  
  const result = http.post('https://'+host+'/scen5_0027', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0028 () {  
  
  const result = http.post('https://'+host+'/scen5_0028', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0029 () {  
  
  const result = http.post('https://'+host+'/scen5_0029', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0030 () {  
  
  const result = http.post('https://'+host+'/scen5_0030', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0031 () {  
  
  const result = http.post('https://'+host+'/scen5_0031', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0032 () {  
  
  const result = http.post('https://'+host+'/scen5_0032', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0033 () {  
  
  const result = http.post('https://'+host+'/scen5_0033', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0034 () {  
  
  const result = http.post('https://'+host+'/scen5_0034', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0035 () {  
  
  const result = http.post('https://'+host+'/scen5_0035', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0036 () {  
  
  const result = http.post('https://'+host+'/scen5_0036', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0037 () {  
  
  const result = http.post('https://'+host+'/scen5_0037', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0038 () {  
  
  const result = http.post('https://'+host+'/scen5_0038', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0039 () {  
  
  const result = http.post('https://'+host+'/scen5_0039', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0040 () {  
  
  const result = http.post('https://'+host+'/scen5_0040', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0041 () {  
  
  const result = http.post('https://'+host+'/scen5_0041', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0042 () {  
  
  const result = http.post('https://'+host+'/scen5_0042', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0043 () {  
  
  const result = http.post('https://'+host+'/scen5_0043', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0044 () {  
  
  const result = http.post('https://'+host+'/scen5_0044', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0045 () {  
  
  const result = http.post('https://'+host+'/scen5_0045', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0046 () {  
  
  const result = http.post('https://'+host+'/scen5_0046', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0047 () {  
  
  const result = http.post('https://'+host+'/scen5_0047', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0048 () {  
  
  const result = http.post('https://'+host+'/scen5_0048', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0049 () {  
  
  const result = http.post('https://'+host+'/scen5_0049', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0050 () {  
  
  const result = http.post('https://'+host+'/scen5_0050', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0051 () {  
  
  const result = http.post('https://'+host+'/scen5_0051', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0052 () {  
  
  const result = http.post('https://'+host+'/scen5_0052', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0053 () {  
  
  const result = http.post('https://'+host+'/scen5_0053', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0054 () {  
  
  const result = http.post('https://'+host+'/scen5_0054', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0055 () {  
  
  const result = http.post('https://'+host+'/scen5_0055', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0056 () {  
  
  const result = http.post('https://'+host+'/scen5_0056', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0057 () {  
  
  const result = http.post('https://'+host+'/scen5_0057', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0058 () {  
  
  const result = http.post('https://'+host+'/scen5_0058', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0059 () {  
  
  const result = http.post('https://'+host+'/scen5_0059', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0060 () {  
  
  const result = http.post('https://'+host+'/scen5_0060', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0061 () {  
  
  const result = http.post('https://'+host+'/scen5_0061', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0062 () {  
  
  const result = http.post('https://'+host+'/scen5_0062', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0063 () {  
  
  const result = http.post('https://'+host+'/scen5_0063', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0064 () {  
  
  const result = http.post('https://'+host+'/scen5_0064', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0065 () {  
  
  const result = http.post('https://'+host+'/scen5_0065', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0066 () {  
  
  const result = http.post('https://'+host+'/scen5_0066', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0067 () {  
  
  const result = http.post('https://'+host+'/scen5_0067', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0068 () {  
  
  const result = http.post('https://'+host+'/scen5_0068', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0069 () {  
  
  const result = http.post('https://'+host+'/scen5_0069', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0070 () {  
  
  const result = http.post('https://'+host+'/scen5_0070', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0071 () {  
  
  const result = http.post('https://'+host+'/scen5_0071', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0072 () {  
  
  const result = http.post('https://'+host+'/scen5_0072', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0073 () {  
  
  const result = http.post('https://'+host+'/scen5_0073', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0074 () {  
  
  const result = http.post('https://'+host+'/scen5_0074', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0075 () {  
  
  const result = http.post('https://'+host+'/scen5_0075', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0076 () {  
  
  const result = http.post('https://'+host+'/scen5_0076', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0077 () {  
  
  const result = http.post('https://'+host+'/scen5_0077', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0078 () {  
  
  const result = http.post('https://'+host+'/scen5_0078', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0079 () {  
  
  const result = http.post('https://'+host+'/scen5_0079', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0080 () {  
  
  const result = http.post('https://'+host+'/scen5_0080', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0081 () {  
  
  const result = http.post('https://'+host+'/scen5_0081', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0082 () {  
  
  const result = http.post('https://'+host+'/scen5_0082', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0083 () {  
  
  const result = http.post('https://'+host+'/scen5_0083', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0084 () {  
  
  const result = http.post('https://'+host+'/scen5_0084', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0085 () {  
  
  const result = http.post('https://'+host+'/scen5_0085', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0086 () {  
  
  const result = http.post('https://'+host+'/scen5_0086', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0087 () {  
  
  const result = http.post('https://'+host+'/scen5_0087', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0088 () {  
  
  const result = http.post('https://'+host+'/scen5_0088', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0089 () {  
  
  const result = http.post('https://'+host+'/scen5_0089', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0090 () {  
  
  const result = http.post('https://'+host+'/scen5_0090', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0091 () {  
  
  const result = http.post('https://'+host+'/scen5_0091', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0092 () {  
  
  const result = http.post('https://'+host+'/scen5_0092', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0093 () {  
  
  const result = http.post('https://'+host+'/scen5_0093', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0094 () {  
  
  const result = http.post('https://'+host+'/scen5_0094', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0095 () {  
  
  const result = http.post('https://'+host+'/scen5_0095', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0096 () {  
  
  const result = http.post('https://'+host+'/scen5_0096', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0097 () {  
  
  const result = http.post('https://'+host+'/scen5_0097', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0098 () {  
  
  const result = http.post('https://'+host+'/scen5_0098', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0099 () {  
  
  const result = http.post('https://'+host+'/scen5_0099', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}
export function scen5endurance_0100 () {  
  
  const result = http.post('https://'+host+'/scen5_0100', calcReq, {
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
      result.body.includes(calcRes),
  });
  
  sleep (calcSleep);
}