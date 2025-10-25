<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpKernel\KernelInterface;
use Symfony\Component\Routing\Annotation\Route;

final class AppController
{
    #[Route('/', name: 'app_spa_root', methods: ['GET'], priority: -100)]

    #[Route(
        '/{reactRouting',
        requirements: ['reactRouting' => '^(?!api|mentions|app/|_(profiler|wdt)).*'],
        methods: ['GET'],
        priority: -100,
    )]

    #[Route(
        '/{reactRouting}',
        name: 'app_spa',
        requirements: ['reactRouting' => '^(?!api|mentions|app/|_(profiler|wdt)).*'],
        methods: ['GET']
    )]
    public function spa(KernelInterface $kernel): BinaryFileResponse
    {
        $file = $kernel->getProjectDir() . '/public/app/index.html';

        return new BinaryFileResponse($file);
    }
}

