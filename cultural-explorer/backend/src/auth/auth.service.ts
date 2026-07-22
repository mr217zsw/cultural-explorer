import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService, private readonly jwt: JwtService) {}
  async anonymous(deviceId: string) {
    const user = await this.prisma.user.upsert({
      where: { deviceId },
      update: { lastLoginAt: new Date() },
      create: { deviceId, nickname: `文化行者${deviceId.slice(-4)}`, lastLoginAt: new Date() },
    });
    return { token: await this.jwt.signAsync({ sub: user.id }), user };
  }
}

