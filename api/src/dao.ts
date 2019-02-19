import * as AWS from 'aws-sdk'
import uuid from 'uuid/v4'
import * as moment from 'moment-timezone';
import { OcrReadData } from './model'

if ('TEGAKI_SAMPLE_AWS_ACCESS_KEY' in process.env) {
  AWS.config.update({
    region: 'ap-northeast-1',
    accessKeyId: process.env.TEGAKI_SAMPLE_AWS_ACCESS_KEY,
    secretAccessKey: process.env.TEGAKI_SAMPLE_AWS_SECRET_ACCESS_KEY,
  })
} else {
  AWS.config.update({
    region: 'ap-northeast-1',
  })
}
const db: AWS.DynamoDB.DocumentClient = new AWS.DynamoDB.DocumentClient()

const s3 = new AWS.S3()

const TABLE_NAME: string = "tegaki_sample"

function buildImageUrl(requestId: string): string {
  return `https://s3-ap-northeast-1.amazonaws.com/tegaki-image/${requestId}`
}

const KEY_PREFIX_OCR_READ_DATA: string = 'OcrReadData_'

async function getOcrReadDatas(): Promise<OcrReadData[]> {
  const res = await db.scan({
    TableName: TABLE_NAME
  }).promise()
  if (res.Items == null) return [];
  return res.Items
    .filter(item => item.key.indexOf(KEY_PREFIX_OCR_READ_DATA) == 0)
    .map(item => {
      return {
        requestId: item.requestId,
        url: buildImageUrl(item.requestId),
        imageWidth: item.imageWidth,
        imageHeight: item.imageHeight,
      }})
}

async function putToDb(req: OcrReadData): Promise<void> {
  await db.put({
    TableName: TABLE_NAME,
    Item: {
      key: KEY_PREFIX_OCR_READ_DATA + uuid(),
      requestId: req.requestId,
      imageWidth: req.imageWidth,
      imageHeight: req.imageHeight,
      updated: formatTime(now()),
    }
  }).promise()
}

async function saveOcrReadData(req: OcrReadData): Promise<OcrReadData> {
  console.log('!!!!!!!')
  console.log('try put to s3.')
  await s3.putObject({
    Bucket: "tegaki-image",
    Key: req.requestId,
    CacheControl: "max-age=31536000",
    Body: new Buffer(req.url.split(",")[1], 'base64'),
  }).promise()

  console.log('!!!!!!!')
  console.log('try put to DynamoDB.')
  await putToDb(req)

  return {
    requestId: req.requestId,
    url: buildImageUrl(req.requestId),
    imageWidth: req.imageWidth,
    imageHeight: req.imageHeight,
  }
}

function now(): moment.Moment {
  return moment().tz('Asia/Tokyo');
}

function formatTime(m: moment.Moment): string {
  return m.format('YYYY-MM-DD HH:mm.ss Z')
}

export {
  getOcrReadDatas,
  saveOcrReadData,
}