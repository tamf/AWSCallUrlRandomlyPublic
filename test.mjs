import { handler } from './index.mjs';

// Define a mock event object
const mockEvent = {
  // Your mock event structure here
};

// Define a mock context object (optional, can be an empty object if context is not used)
const mockContext = {};

// Call the handler function to simulate a Lambda invocation
handler(mockEvent, mockContext)
  .then(response => console.log('Lambda response:', response))
  .catch(err => console.error('Lambda error:', err));