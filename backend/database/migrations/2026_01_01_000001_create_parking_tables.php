<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Hier erstellen wir alle Tabellen für die Parkplatz-App.
return new class extends Migration
{
    public function up(): void
    {
        // Ein Tenant ist ein Kunde (z.B. eine Stadt oder eine Firma).
        Schema::create('tenants', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();          // für die Subdomain: slug.parking.app
            $table->string('primary_color', 7)->default('#2563eb'); // White-Label-Farbe
            $table->string('logo_url')->nullable();
            $table->string('currency', 3)->default('EUR');
            $table->timestamps();
        });

        // Jeder Benutzer gehört zu genau einem Tenant.
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('tenant_id')->nullable()->after('id')->constrained()->cascadeOnDelete();
            $table->string('role')->default('driver'); // driver | operator | admin
        });

        Schema::create('parking_lots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('address')->nullable();
            $table->unsignedInteger('capacity');
            // Preise speichern wir in Cent. So gibt es keine Rundungsfehler.
            $table->unsignedInteger('hourly_rate_cents');
            $table->unsignedInteger('free_minutes')->default(0);
            $table->unsignedInteger('daily_cap_cents')->nullable();
            $table->timestamps();
            $table->index(['tenant_id', 'name']);
        });

        Schema::create('parking_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('parking_lot_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('license_plate', 16);
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();   // null = Auto steht noch da
            $table->unsignedInteger('amount_cents')->nullable();
            $table->timestamps();
            $table->index(['tenant_id', 'parking_lot_id', 'ended_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('parking_sessions');
        Schema::dropIfExists('parking_lots');
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('tenant_id');
            $table->dropColumn('role');
        });
        Schema::dropIfExists('tenants');
    }
};
