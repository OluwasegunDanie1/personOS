import { PasswordHashService } from './password-hash.service';

describe('PasswordHashService', () => {
  const service = new PasswordHashService();
  const password = 'correct horse battery staple';

  it('produces an Argon2id hash', async () => {
    const hash = await service.hash(password);

    expect(hash.startsWith('$argon2id$')).toBe(true);
  });

  it('verifies the correct password', async () => {
    const hash = await service.hash(password);

    await expect(service.verify(hash, password)).resolves.toBe(true);
  });

  it('rejects an incorrect password', async () => {
    const hash = await service.hash(password);

    await expect(service.verify(hash, 'wrong password')).resolves.toBe(false);
  });
});
