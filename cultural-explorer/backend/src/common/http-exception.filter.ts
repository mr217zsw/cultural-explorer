import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';

type HttpResponse = { status(code: number): { json(body: unknown): void } };

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<HttpResponse>();
    const status = exception instanceof HttpException ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;
    const detail = exception instanceof HttpException ? exception.getResponse() : null;
    const rawMessage = typeof detail === 'string' ? detail : (detail as { message?: string | string[] } | null)?.message;
    const message = Array.isArray(rawMessage) ? rawMessage.join('；') : rawMessage ?? '服务器内部错误';
    const code = status === 400 ? 1001 : status === 401 ? 1002 : status === 403 ? 1003 : status === 404 ? 1004 : 5000;
    response.status(status).json({ code, message, data: null, timestamp: Date.now() });
  }
}
