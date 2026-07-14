export const REFRESH_TOKEN_LIFETIME_MS = 30 * 24 * 60 * 60 * 1000;

// Per 16_Security.md's Password Reset Security section: reset tokens must
// expire exactly 1 hour after creation.
export const PASSWORD_RESET_TOKEN_LIFETIME_MS = 60 * 60 * 1000;

// Exact wording from 16_Security.md's approved non-disclosing example
// response — never reveals whether the supplied email resolved to a User.
export const FORGOT_PASSWORD_MESSAGE = 'If an account exists for this email, password reset instructions will be sent.';

export const AUTH_ERROR_CODES = {
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  INVALID_REFRESH_TOKEN: 'INVALID_REFRESH_TOKEN',
  USER_DISABLED: 'USER_DISABLED',
  AUTHENTICATION_REQUIRED: 'AUTHENTICATION_REQUIRED',
  INVALID_ACCESS_TOKEN: 'INVALID_ACCESS_TOKEN',
  EMAIL_ALREADY_REGISTERED: 'EMAIL_ALREADY_REGISTERED',
  // One shared code for an absent, expired, or already-used reset token —
  // mirrors INVALID_CREDENTIALS's "never reveal which factor failed"
  // convention so a caller can never distinguish these states.
  INVALID_RESET_TOKEN: 'INVALID_RESET_TOKEN',
} as const;
