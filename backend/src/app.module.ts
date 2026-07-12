import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { AccessTokenGuard } from './common/guards/access-token.guard';
import { DatabaseModule } from './database/database.module';
import { EventsModule } from './events/events.module';
import { FollowUpsModule } from './follow-ups/follow-ups.module';
import { JourneyModule } from './journey/journey.module';
import { OrganizationsModule } from './organizations/organizations.module';
import { PeopleModule } from './people/people.module';
import { SecurityModule } from './security/security.module';

@Module({
  imports: [
    DatabaseModule,
    SecurityModule,
    AuthModule,
    OrganizationsModule,
    PeopleModule,
    JourneyModule,
    EventsModule,
    FollowUpsModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: AccessTokenGuard }],
})
export class AppModule {}
