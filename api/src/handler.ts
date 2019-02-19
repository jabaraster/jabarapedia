import {
  APIGatewayProxyHandler, APIGatewayProxyResult
} from 'aws-lambda'

import * as dao from './dao'
import { Language } from './model'

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

function resNoContent(headers?: { [name: string]: string }): APIGatewayProxyResult {
  return res({
    statusCode: 204,
    headers: headers == null ? {} : headers,
    body: ""
  })
}

const options: APIGatewayProxyHandler = async () => {
  return resOk()
}

const getLanguages: APIGatewayProxyHandler = async () => {
  const res = await dao.getLanguages()
  return resOk(res)
}

const postLanguage: APIGatewayProxyHandler = async (evt) => {
  const body: Language = JSON.parse(evt.body as string)
  await dao.postLanguage(body)
  return resNoContent()
}

export {
  options,
  getLanguages,
  postLanguage,
}
