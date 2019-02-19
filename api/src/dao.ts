import * as AWS from 'aws-sdk'
import uuid from 'uuid/v4'
import { Language } from './model'

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

async function postLanguage(data: Language): Promise<void> {
  const d = JSON.parse(JSON.stringify(data))
  d.kind = 'Language'
  d.id = uuid()
  console.log(d)
  await db.put({
    TableName: TABLE_NAME,
    Item: d,
  }).promise()
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
    console.log(item)
    return {
      meta: {
        lightWeight: true,
        staticTyping: true,
      },
      name: 'Haskell',
      path: 'haskell',
      impression: 'ツンデレ',
    }
  })
}

export {
  getLanguages,
  postLanguage,
}