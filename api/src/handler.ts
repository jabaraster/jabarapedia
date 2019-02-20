import { APIGatewayProxyHandler } from 'aws-lambda'

import * as dao from './dao'
import { Language } from './model'
import { HttpReturnCode, newResultDecorator } from './handler-util'

const r = newResultDecorator('https://jabarapedia.jabara.info')

export const options = r.options

export const getLanguages: APIGatewayProxyHandler = async () => {
  const res = await dao.getLanguages()
  return r.ok(res)
}

export const postLanguage: APIGatewayProxyHandler = async (evt) => {
  console.log(evt.body)
  const body: Language = JSON.parse(evt.body as string)
  const res = await dao.postLanguage(body)
  if (res.fail != null) return r.general(HttpReturnCode.BAD_REQUEST, {errorMessage: res.fail})
  return r.created(null)
}