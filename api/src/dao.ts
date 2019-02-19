import * as AWS from 'aws-sdk'
import { Failable, Empty, success, fail, Language } from './model'

if ('JABARAPEDIA_AWS_ACCESS_KEY' in process.env) {
  AWS.config.update({
    region: 'ap-northeast-1',
    accessKeyId: process.env.JABARAPEDIA_AWS_ACCESS_KEY,
    secretAccessKey: process.env.JABARAPEDIA_AWS_SECRET_ACCESS_KEY,
  })
} else {
  AWS.config.update({
    region: 'ap-northeast-1',
  })
}
const db: AWS.DynamoDB.DocumentClient = new AWS.DynamoDB.DocumentClient()

// const s3 = new AWS.S3()

const TABLE_NAME: string = "jabarapedia_dev"

async function postLanguage(data: Language): Promise<Failable<Empty, string>> {
  // 存在チェック
  const res = await db.get({
    TableName: TABLE_NAME,
    Key: {
      kind: 'Language',
      id: data.path,
    }
  }).promise()
  if (res.Item != null) return fail('key duplicate.')

  const d = JSON.parse(JSON.stringify(data))
  d.kind = 'Language'
  d.id = data.path
  delete d.path
  await db.put({
    TableName: TABLE_NAME,
    Item: d,
  }).promise()
  return success({})
}

async function getLanguages(): Promise<Language[]> {
  const res = await db.query({
    TableName: TABLE_NAME,
    KeyConditionExpression: 'kind = :kind',
    ExpressionAttributeValues: {
      ':kind': 'Language',
    }
  }).promise()
  if (res.Items == null) return [];
  return res.Items.map(item => {
      item.path = item.id
      return item as Language
  })
}

export {
  getLanguages,
  postLanguage,
}