import { Controller, Get, Module } from '@nestjs/common';
import type { HealthResponse } from '@lms/contracts';

@Controller('health')
class HealthController {
  @Get()
  check(): HealthResponse { return { status: 'ok', service: 'lms-api' }; }
}

@Module({ controllers: [HealthController] })
export class HealthModule {}
