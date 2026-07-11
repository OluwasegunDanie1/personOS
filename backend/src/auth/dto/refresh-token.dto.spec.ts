import { ArgumentMetadata, BadRequestException, ValidationPipe } from '@nestjs/common';
import { RefreshTokenDto } from './refresh-token.dto';

describe('RefreshTokenDto validation', () => {
  const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });
  const metadata: ArgumentMetadata = { type: 'body', metatype: RefreshTokenDto, data: '' };

  it('rejects an empty token', async () => {
    await expect(pipe.transform({ refreshToken: '' }, metadata)).rejects.toThrow(BadRequestException);
  });

  it('accepts a valid payload', async () => {
    const result = await pipe.transform({ refreshToken: 'some-token' }, metadata);

    expect(result).toBeInstanceOf(RefreshTokenDto);
  });
});
