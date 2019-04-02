import { APIGatewayProxyHandler } from 'aws-lambda'

import * as dao from './dao'
import { Language } from './model'
import { HttpReturnCode, newResultDecorator } from './handler-util'

const r = newResultDecorator('https://jabarapedia.jabara.info')

export const options = r.options

export const getLanguages: APIGatewayProxyHandler = async () => {
  const res = await dao.getLanguages()
  return r.ok(res.map(lang => {
    delete lang.impression
    return lang
  }))
}

export const postLanguage: APIGatewayProxyHandler = async (evt) => {
  const body: Language = JSON.parse(evt.body as string)
  const res = await dao.createLanguage(body)
  if (res.fail != null) return r.general(HttpReturnCode.BAD_REQUEST, {errorMessage: res.fail})
  return r.created(null)
}

export const getLanguage: APIGatewayProxyHandler = async (evt) => {
  const li = evt.pathParameters!!.languageId
  if (li == null) return r.general(HttpReturnCode.NOT_FOUND)
  const res = await dao.getLanguage(li)
  if (res.fail != null) return r.general(HttpReturnCode.NOT_FOUND, { errorMessage: `language ${li} not found.` })
  return r.ok(res.success)
}

export const putLanguage: APIGatewayProxyHandler = async (evt) => {
  const li = evt.pathParameters!!.languageId
  if (li == null) return r.general(HttpReturnCode.NOT_FOUND)
  const body: Language = JSON.parse(evt.body as string)
  body.path = li
  const res = await dao.updateLanguage(body)
  console.log(res)
  if (res.fail != null) return r.general(HttpReturnCode.BAD_REQUEST, { errorMessage: res.fail })
  return r.noContent()
}