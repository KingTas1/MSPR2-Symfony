<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpKernel\KernelInterface;
use Symfony\Component\Routing\Annotation\Route;

final class AppController
{
    #[Route('/', name: 'app_spa_root', methods: ['GET'])]
    public function root(): RedirectResponse
    {
        return new RedirectResponse('/app');
    }

    #[Route('/app', name: 'app_index', methods: ['GET'])]
    #[Route('/app/{reactRouting}', name: 'app_spa', requirements: ['reactRouting' => '.*'], methods: ['GET'])]
    public function spa(KernelInterface $kernel): BinaryFileResponse
    {
        $file = $kernel->getProjectDir() . '/public/app/index.html';
        return new BinaryFileResponse($file);
    }
}
