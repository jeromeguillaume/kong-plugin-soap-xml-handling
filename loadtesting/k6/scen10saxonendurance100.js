import http from 'k6/http';
import { check } from 'k6';
import { sleep } from 'k6';

const host='kong-proxy.kong:8443';
//const host='34.38.216.67';

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

const calcSleep = 0.650;

export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    scen10saxonendurance_0001: {
      exec: 'scen10saxonendurance_0001',
      
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
    scen10saxonendurance_0002: {
      exec: 'scen10saxonendurance_0002',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0003: {
      exec: 'scen10saxonendurance_0003',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0004: {
      exec: 'scen10saxonendurance_0004',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0005: {
      exec: 'scen10saxonendurance_0005',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0006: {
      exec: 'scen10saxonendurance_0006',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0007: {
      exec: 'scen10saxonendurance_0007',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0008: {
      exec: 'scen10saxonendurance_0008',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0009: {
      exec: 'scen10saxonendurance_0009',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0010: {
      exec: 'scen10saxonendurance_0010',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },  
    scen10saxonendurance_0011: {
      exec: 'scen10saxonendurance_0011',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },    
    scen10saxonendurance_0012: {
      exec: 'scen10saxonendurance_0012',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0013: {
      exec: 'scen10saxonendurance_0013',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0014: {
      exec: 'scen10saxonendurance_0014',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0015: {
      exec: 'scen10saxonendurance_0015',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0016: {
      exec: 'scen10saxonendurance_0016',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0017: {
      exec: 'scen10saxonendurance_0017',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0018: {
      exec: 'scen10saxonendurance_0018',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0019: {
      exec: 'scen10saxonendurance_0019',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0020: {
      exec: 'scen10saxonendurance_0020',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },  
    scen10saxonendurance_0021: {
      exec: 'scen10saxonendurance_0021',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },    
    scen10saxonendurance_0022: {
      exec: 'scen10saxonendurance_0022',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0023: {
      exec: 'scen10saxonendurance_0023',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0024: {
      exec: 'scen10saxonendurance_0024',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0025: {
      exec: 'scen10saxonendurance_0025',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0026: {
      exec: 'scen10saxonendurance_0026',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0027: {
      exec: 'scen10saxonendurance_0027',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0028: {
      exec: 'scen10saxonendurance_0028',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0029: {
      exec: 'scen10saxonendurance_0029',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0030: {
      exec: 'scen10saxonendurance_0030',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },  
    scen10saxonendurance_0031: {
      exec: 'scen10saxonendurance_0031',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },    
    scen10saxonendurance_0032: {
      exec: 'scen10saxonendurance_0032',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0033: {
      exec: 'scen10saxonendurance_0033',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0034: {
      exec: 'scen10saxonendurance_0034',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0035: {
      exec: 'scen10saxonendurance_0035',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0036: {
      exec: 'scen10saxonendurance_0036',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0037: {
      exec: 'scen10saxonendurance_0037',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0038: {
      exec: 'scen10saxonendurance_0038',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0039: {
      exec: 'scen10saxonendurance_0039',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0040: {
      exec: 'scen10saxonendurance_0040',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },  
    scen10saxonendurance_0041: {
      exec: 'scen10saxonendurance_0041',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },    
    scen10saxonendurance_0042: {
      exec: 'scen10saxonendurance_0042',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0043: {
      exec: 'scen10saxonendurance_0043',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0044: {
      exec: 'scen10saxonendurance_0044',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0045: {
      exec: 'scen10saxonendurance_0045',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0046: {
      exec: 'scen10saxonendurance_0046',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0047: {
      exec: 'scen10saxonendurance_0047',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0048: {
      exec: 'scen10saxonendurance_0048',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0049: {
      exec: 'scen10saxonendurance_0049',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0050: {
      exec: 'scen10saxonendurance_0050',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },  
    scen10saxonendurance_0051: {
      exec: 'scen10saxonendurance_0051',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },    
    scen10saxonendurance_0052: {
      exec: 'scen10saxonendurance_0052',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0053: {
      exec: 'scen10saxonendurance_0053',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0054: {
      exec: 'scen10saxonendurance_0054',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0055: {
      exec: 'scen10saxonendurance_0055',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0056: {
      exec: 'scen10saxonendurance_0056',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0057: {
      exec: 'scen10saxonendurance_0057',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0058: {
      exec: 'scen10saxonendurance_0058',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0059: {
      exec: 'scen10saxonendurance_0059',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0060: {
      exec: 'scen10saxonendurance_0060',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },  
    scen10saxonendurance_0061: {
      exec: 'scen10saxonendurance_0061',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },    
    scen10saxonendurance_0062: {
      exec: 'scen10saxonendurance_0062',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0063: {
      exec: 'scen10saxonendurance_0063',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0064: {
      exec: 'scen10saxonendurance_0064',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0065: {
      exec: 'scen10saxonendurance_0065',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0066: {
      exec: 'scen10saxonendurance_0066',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0067: {
      exec: 'scen10saxonendurance_0067',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0068: {
      exec: 'scen10saxonendurance_0068',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0069: {
      exec: 'scen10saxonendurance_0069',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0070: {
      exec: 'scen10saxonendurance_0070',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },  
    scen10saxonendurance_0071: {
      exec: 'scen10saxonendurance_0071',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },    
    scen10saxonendurance_0072: {
      exec: 'scen10saxonendurance_0072',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0073: {
      exec: 'scen10saxonendurance_0073',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0074: {
      exec: 'scen10saxonendurance_0074',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0075: {
      exec: 'scen10saxonendurance_0075',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0076: {
      exec: 'scen10saxonendurance_0076',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0077: {
      exec: 'scen10saxonendurance_0077',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0078: {
      exec: 'scen10saxonendurance_0078',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0079: {
      exec: 'scen10saxonendurance_0079',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0080: {
      exec: 'scen10saxonendurance_0080',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },  
    scen10saxonendurance_0081: {
      exec: 'scen10saxonendurance_0081',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },    
    scen10saxonendurance_0082: {
      exec: 'scen10saxonendurance_0082',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0083: {
      exec: 'scen10saxonendurance_0083',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0084: {
      exec: 'scen10saxonendurance_0084',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0085: {
      exec: 'scen10saxonendurance_0085',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0086: {
      exec: 'scen10saxonendurance_0086',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0087: {
      exec: 'scen10saxonendurance_0087',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0088: {
      exec: 'scen10saxonendurance_0088',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0089: {
      exec: 'scen10saxonendurance_0089',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0090: {
      exec: 'scen10saxonendurance_0090',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },  
    scen10saxonendurance_0091: {
      exec: 'scen10saxonendurance_0091',
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },    
    scen10saxonendurance_0092: {
      exec: 'scen10saxonendurance_0092',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0093: {
      exec: 'scen10saxonendurance_0093',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0094: {
      exec: 'scen10saxonendurance_0094',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0095: {
      exec: 'scen10saxonendurance_0095',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0096: {
      exec: 'scen10saxonendurance_0096',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0097: {
      exec: 'scen10saxonendurance_0097',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0098: {
      exec: 'scen10saxonendurance_0098',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0099: {
      exec: 'scen10saxonendurance_0099',
      
      executor: 'ramping-vus',
      startvus: 0,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '24h', target: 20 },
      ],
      gracefulRampDown: '30s',
    },
    scen10saxonendurance_0100: {
      exec: 'scen10saxonendurance_0100',
      
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

export function scen10saxonendurance_0001 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0001/anything', XMLRequest, {
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
export function scen10saxonendurance_0002 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0002/anything', XMLRequest, {
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
export function scen10saxonendurance_0003 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0003/anything', XMLRequest, {
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
export function scen10saxonendurance_0004 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0004/anything', XMLRequest, {
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
export function scen10saxonendurance_0005 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0005/anything', XMLRequest, {
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
export function scen10saxonendurance_0006 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0006/anything', XMLRequest, {
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
export function scen10saxonendurance_0007 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0007/anything', XMLRequest, {
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
export function scen10saxonendurance_0008 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0008/anything', XMLRequest, {
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
export function scen10saxonendurance_0009 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0009/anything', XMLRequest, {
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
export function scen10saxonendurance_0010 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0010/anything', XMLRequest, {
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
export function scen10saxonendurance_0011 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0011/anything', XMLRequest, {
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
export function scen10saxonendurance_0012 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0012/anything', XMLRequest, {
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
export function scen10saxonendurance_0013 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0013/anything', XMLRequest, {
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
export function scen10saxonendurance_0014 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0014/anything', XMLRequest, {
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
export function scen10saxonendurance_0015 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0015/anything', XMLRequest, {
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
export function scen10saxonendurance_0016 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0016/anything', XMLRequest, {
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
export function scen10saxonendurance_0017 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0017/anything', XMLRequest, {
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
export function scen10saxonendurance_0018 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0018/anything', XMLRequest, {
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
export function scen10saxonendurance_0019 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0019/anything', XMLRequest, {
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
export function scen10saxonendurance_0020 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0020/anything', XMLRequest, {
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
export function scen10saxonendurance_0021 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0021/anything', XMLRequest, {
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
export function scen10saxonendurance_0022 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0022/anything', XMLRequest, {
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
export function scen10saxonendurance_0023 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0023/anything', XMLRequest, {
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
export function scen10saxonendurance_0024 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0024/anything', XMLRequest, {
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
export function scen10saxonendurance_0025 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0025/anything', XMLRequest, {
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
export function scen10saxonendurance_0026 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0026/anything', XMLRequest, {
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
export function scen10saxonendurance_0027 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0027/anything', XMLRequest, {
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
export function scen10saxonendurance_0028 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0028/anything', XMLRequest, {
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
export function scen10saxonendurance_0029 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0029/anything', XMLRequest, {
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
export function scen10saxonendurance_0030 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0030/anything', XMLRequest, {
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
export function scen10saxonendurance_0031 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0031/anything', XMLRequest, {
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
export function scen10saxonendurance_0032 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0032/anything', XMLRequest, {
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
export function scen10saxonendurance_0033 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0033/anything', XMLRequest, {
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
export function scen10saxonendurance_0034 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0034/anything', XMLRequest, {
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
export function scen10saxonendurance_0035 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0035/anything', XMLRequest, {
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
export function scen10saxonendurance_0036 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0036/anything', XMLRequest, {
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
export function scen10saxonendurance_0037 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0037/anything', XMLRequest, {
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
export function scen10saxonendurance_0038 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0038/anything', XMLRequest, {
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
export function scen10saxonendurance_0039 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0039/anything', XMLRequest, {
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
export function scen10saxonendurance_0040 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0040/anything', XMLRequest, {
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
export function scen10saxonendurance_0041 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0041/anything', XMLRequest, {
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
export function scen10saxonendurance_0042 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0042/anything', XMLRequest, {
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
export function scen10saxonendurance_0043 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0043/anything', XMLRequest, {
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
export function scen10saxonendurance_0044 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0044/anything', XMLRequest, {
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
export function scen10saxonendurance_0045 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0045/anything', XMLRequest, {
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
export function scen10saxonendurance_0046 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0046/anything', XMLRequest, {
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
export function scen10saxonendurance_0047 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0047/anything', XMLRequest, {
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
export function scen10saxonendurance_0048 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0048/anything', XMLRequest, {
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
export function scen10saxonendurance_0049 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0049/anything', XMLRequest, {
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
export function scen10saxonendurance_0050 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0050/anything', XMLRequest, {
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
export function scen10saxonendurance_0051 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0051/anything', XMLRequest, {
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
export function scen10saxonendurance_0052 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0052/anything', XMLRequest, {
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
export function scen10saxonendurance_0053 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0053/anything', XMLRequest, {
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
export function scen10saxonendurance_0054 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0054/anything', XMLRequest, {
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
export function scen10saxonendurance_0055 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0055/anything', XMLRequest, {
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
export function scen10saxonendurance_0056 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0056/anything', XMLRequest, {
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
export function scen10saxonendurance_0057 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0057/anything', XMLRequest, {
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
export function scen10saxonendurance_0058 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0058/anything', XMLRequest, {
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
export function scen10saxonendurance_0059 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0059/anything', XMLRequest, {
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
export function scen10saxonendurance_0060 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0060/anything', XMLRequest, {
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
export function scen10saxonendurance_0061 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0061/anything', XMLRequest, {
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
export function scen10saxonendurance_0062 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0062/anything', XMLRequest, {
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
export function scen10saxonendurance_0063 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0063/anything', XMLRequest, {
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
export function scen10saxonendurance_0064 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0064/anything', XMLRequest, {
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
export function scen10saxonendurance_0065 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0065/anything', XMLRequest, {
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
export function scen10saxonendurance_0066 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0066/anything', XMLRequest, {
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
export function scen10saxonendurance_0067 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0067/anything', XMLRequest, {
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
export function scen10saxonendurance_0068 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0068/anything', XMLRequest, {
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
export function scen10saxonendurance_0069 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0069/anything', XMLRequest, {
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
export function scen10saxonendurance_0070 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0070/anything', XMLRequest, {
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
export function scen10saxonendurance_0071 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0071/anything', XMLRequest, {
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
export function scen10saxonendurance_0072 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0072/anything', XMLRequest, {
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
export function scen10saxonendurance_0073 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0073/anything', XMLRequest, {
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
export function scen10saxonendurance_0074 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0074/anything', XMLRequest, {
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
export function scen10saxonendurance_0075 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0075/anything', XMLRequest, {
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
export function scen10saxonendurance_0076 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0076/anything', XMLRequest, {
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
export function scen10saxonendurance_0077 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0077/anything', XMLRequest, {
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
export function scen10saxonendurance_0078 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0078/anything', XMLRequest, {
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
export function scen10saxonendurance_0079 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0079/anything', XMLRequest, {
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
export function scen10saxonendurance_0080 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0080/anything', XMLRequest, {
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
export function scen10saxonendurance_0081 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0081/anything', XMLRequest, {
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
export function scen10saxonendurance_0082 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0082/anything', XMLRequest, {
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
export function scen10saxonendurance_0083 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0083/anything', XMLRequest, {
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
export function scen10saxonendurance_0084 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0084/anything', XMLRequest, {
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
export function scen10saxonendurance_0085 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0085/anything', XMLRequest, {
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
export function scen10saxonendurance_0086 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0086/anything', XMLRequest, {
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
export function scen10saxonendurance_0087 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0087/anything', XMLRequest, {
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
export function scen10saxonendurance_0088 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0088/anything', XMLRequest, {
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
export function scen10saxonendurance_0089 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0089/anything', XMLRequest, {
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
export function scen10saxonendurance_0090 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0090/anything', XMLRequest, {
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
export function scen10saxonendurance_0091 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0091/anything', XMLRequest, {
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
export function scen10saxonendurance_0092 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0092/anything', XMLRequest, {
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
export function scen10saxonendurance_0093 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0093/anything', XMLRequest, {
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
export function scen10saxonendurance_0094 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0094/anything', XMLRequest, {
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
export function scen10saxonendurance_0095 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0095/anything', XMLRequest, {
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
export function scen10saxonendurance_0096 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0096/anything', XMLRequest, {
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
export function scen10saxonendurance_0097 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0097/anything', XMLRequest, {
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
export function scen10saxonendurance_0098 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0098/anything', XMLRequest, {
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
export function scen10saxonendurance_0099 () {    
  
  const result = http.post('https://'+host+'/scen10saxon_0099/anything', XMLRequest, {
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
export function scen10saxonendurance_0100 () {    

  const result = http.post('https://'+host+'/scen10saxon_0100/anything', XMLRequest, {
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