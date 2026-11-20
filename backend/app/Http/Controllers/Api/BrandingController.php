<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Tenancy\TenantContext;
use Illuminate\Http\JsonResponse;

// White-Label: Das Frontend fragt hier nach Name, Farbe und Logo vom Kunden.
class BrandingController extends Controller
{
    public function __invoke(TenantContext $context): JsonResponse
    {
        $t = $context->get();

        return response()->json([
            'name' => $t->name,
            'slug' => $t->slug,
            'primary_color' => $t->primary_color,
            'logo_url' => $t->logo_url,
            'currency' => $t->currency,
        ]);
    }
}
