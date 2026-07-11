import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

interface AccessTokenPayload {
  sub: string;
}

@Injectable()
export class AccessTokenService {
  constructor(private readonly jwtService: JwtService) {}

  sign(userId: string): string {
    const payload: AccessTokenPayload = { sub: userId };
    return this.jwtService.sign(payload);
  }
}
