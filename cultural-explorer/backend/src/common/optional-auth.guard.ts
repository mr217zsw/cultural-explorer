import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class OptionalAuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}
  canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<{ headers: Record<string, string>; user?: { sub: string } }>();
    const token = request.headers.authorization?.replace(/^Bearer\s+/i, '');
    if (token) {
      try { request.user = this.jwt.verify<{ sub: string }>(token); } catch { /* Public endpoints tolerate an invalid/missing session. */ }
    }
    return true;
  }
}
