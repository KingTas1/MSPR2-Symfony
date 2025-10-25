<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\Routing\Annotation\Route;

final class AppController
{
    #[Route(
        '/{reactRouting}',
        name: 'app_spa',
        requirements: ['reactRouting' => '^(?!api|mentions|app/|_(profiler|wdt)).*'],
        methods: ['GET']
    )]
    public function spa(): BinaryFileResponse
    {
        // remonte de src/Controller à la racine du projet
        $projectDir = \dirname(__DIR__, 2);
        $file = $projectDir . '/public/app/index.html';

        return new BinaryFileResponse($file);
    }
}

