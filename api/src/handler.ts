import {
  APIGatewayProxyHandler, APIGatewayProxyResult
} from 'aws-lambda'
import axios from 'axios'

import { OcrReadData } from './model'
import * as dao from './dao'

function res(result: APIGatewayProxyResult): APIGatewayProxyResult {
  if (!result.headers) {
    result.headers = {}
  }
  result.headers['Access-Control-Allow-Origin'] = 'https://jabarapedia.jabara.info'
  result.headers['Access-Control-Allow-Credentials'] = true
  result.headers['Access-Control-Allow-Headers'] = 'Content-Type'
  return result
}

function resOk(body?: any, headers?: { [name: string]: string }): APIGatewayProxyResult {
  return res({
    statusCode: 200,
    headers: headers == null ? {} : headers,
    body: JSON.stringify(body)
  })
}

// function resNoContent(headers?: { [name: string]: string }): APIGatewayProxyResult {
//   return res({
//     statusCode: 204,
//     headers: headers == null ? {} : headers,
//     body: ""
//   })
// }

const options: APIGatewayProxyHandler = async () => {
  return resOk()
}

const getOcrReadDatas: APIGatewayProxyHandler = async () => {
  const ret: OcrReadData[] = await dao.getOcrReadDatas()
  return resOk(ret)
}

const postOcrReadData: APIGatewayProxyHandler = async (event) => {
  const body: OcrReadData = JSON.parse(event.body as string)
  const res = await dao.saveOcrReadData(body)
  return resOk(res)
}

export {
  options,
  getOcrReadDatas,
  postOcrReadData,
}
