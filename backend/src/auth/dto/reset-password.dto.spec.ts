import { ArgumentMetadata, BadRequestException, ValidationPipe } from '@nestjs/common';
import { ResetPasswordDto } from './reset-password.dto';

describe('ResetPasswordDto validation', () => {
  const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });
  const metadata: ArgumentMetadata = { type: 'body', metatype: ResetPasswordDto, data: '' };

  const validPayload = { token: 'raw-token', newPassword: 'brand-new-password' };

  it('accepts a valid payload', async () => {
    const result = await pipe.transform(validPayload, metadata);
    expect(result).toBeInstanceOf(ResetPasswordDto);
  });

  it('rejects an empty token', async () => {
    await expect(pipe.transform({ ...validPayload, token: '' }, metadata)).rejects.toThrow(BadRequestException);
  });

  it('rejects a newPassword shorter than 8 characters', async () => {
    await expect(pipe.transform({ ...validPayload, newPassword: 'short' }, metadata)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('rejects extra fields not defined on the DTO', async () => {
    await expect(pipe.transform({ ...validPayload, userId: 'attacker' }, metadata)).rejects.toThrow(
      BadRequestException,
    );
  });
});
