import { APIGatewayProxyHandler, APIGatewayProxyResult } from 'aws-lambda'

export const HttpReturnCode = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,

  BAD_REQUEST: 400,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
}

export type Headers = { string: string }
export type Body = any

export type ResultDecorator = {
  general: (HttpReturnCode, Body?, Headers?) => APIGatewayProxyResult,
  ok: (Body, Headers?) => APIGatewayProxyResult,
  created: (Body, Headers?) => APIGatewayProxyResult,
  noContent: (Headers?) => APIGatewayProxyResult,
  options: APIGatewayProxyHandler,
}

export function newResultDecorator(allowOrigin: string): ResultDecorator {
  const core = function (result: APIGatewayProxyResult): APIGatewayProxyResult {
    if (!result.headers) {
      result.headers = {}
    }
    result.headers['Access-Control-Allow-Origin'] = allowOrigin
    result.headers['Access-Control-Allow-Credentials'] = true
    result.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    result.headers['Access-Control-Allow-Methods'] = 'GET,POST,PUT,DELETE,HEAD'
    return result
  }
  const general = (statusCode, body, headers) => core({
    statusCode,
    headers,
    body: JSON.stringify(body),
  })
  return {
    general,
    ok: (body, headers) => general(HttpReturnCode.OK, body, headers),
    created: (body, headers) => general(HttpReturnCode.CREATED, body, headers),
    noContent: (headers) => general(HttpReturnCode.NO_CONTENT, null, headers),
    options: async () => general(HttpReturnCode.OK, null, null)
  }
}