import fetch from 'node-fetch';
import moment from 'moment-timezone';
import { SchedulerClient, UpdateScheduleCommand } from '@aws-sdk/client-scheduler';

// define the URLs here that you want to be hit. Only one URL gets hit per execution, chosen randomly
const URLS = [
  'https://example.com',
  'https://example.org',
  'https://example.net'
];

const SCHEDULE_NAME = 'CallUrlScheduler';
const TIMEZONE = ''; // IANA Time Zone Identifier, e.g. 'Europe/Paris'
const AWS_REGION = '';
const HOUR_EARLIEST = 9; // earliest hour (24h clock) that the function can be scheduled
const HOUR_LATEST = 18; // latest hour (24h clock) that the function can be scheduled
const LAMBDA_ARN = 'arn:aws:lambda:...';
const ROLE_ARN = 'arn:aws:iam::...';
const DLQ_ARN = 'arn:aws:sqs:...';

const schedulerClient = new SchedulerClient({ region: AWS_REGION });

export const handler = async (event) => {
  await Promise.all([
    hitEndpoint(),
    setNextSchedule()
  ]);
};

const setNextSchedule = async () => {
  const now = moment().tz(TIMEZONE);

  // Generate a random hour
  const randomHour = Math.floor(Math.random() * (HOUR_LATEST - HOUR_EARLIEST + 1)) + HOUR_EARLIEST;

  // Decide if the next run should be today or tomorrow
  const todayOrTomorrow = now.hour() >= randomHour ? now.clone().add(1, 'days') : now;

  // Format day of the week for the cron expression (1-7)
  const dayOfWeek = todayOrTomorrow.isoWeekday() % 7 + 1;

  const input = {
    Name: SCHEDULE_NAME,
    ScheduleExpression: `cron(0 ${randomHour} ? * ${dayOfWeek} *)`,
    State: 'ENABLED',
    FlexibleTimeWindow: {
      Mode: 'FLEXIBLE', // this adds some randomness to when during that hour the URL gets called
      MaximumWindowInMinutes: 60
    },
    Target: {
      Arn: LAMBDA_ARN,
      RoleArn: ROLE_ARN,
      DeadLetterConfig: {
        Arn: DLQ_ARN
      },
      RetryPolicy: {
        MaximumRetryAttempts: 1
      }
    },
    ScheduleExpressionTimezone: TIMEZONE
  };

  try {
    const command = new UpdateScheduleCommand(input);
    await schedulerClient.send(command);
    console.log('Successfully updated EventBridge schedule with new cron expression:', input.ScheduleExpression);
  } catch (error) {
    console.error('Error updating EventBridge schedule:', error);
    throw error;
  }
}

const hitEndpoint = async () => {
  const chosenUrl = randomlyChooseUrl();
  try {
    const response = await fetch(chosenUrl);

    if (!response.ok) {
      throw new Error(`HTTP error, status: ${response.status}`);
    }

    console.log(`Successfully fetched from ${chosenUrl}`);
  } catch (error) {
    console.error(`Error fetching ${chosenUrl}:`, error);
    throw error;
  }
}

const randomlyChooseUrl = () => {
  return URLS[Math.floor(Math.random() * URLS.length)];
}