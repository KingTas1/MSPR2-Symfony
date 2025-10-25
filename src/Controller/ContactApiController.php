<?php

namespace App\Controller;

use App\Entity\ContactMessage;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\{Request, JsonResponse};
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Component\Validator\Validator\ValidatorInterface;

final class ContactApiController
{
    #[Route('/api/message', name: 'api_contact_message', methods: ['POST'])]
    #[Route('/api/contact', name: 'api_contact_legacy', methods: ['POST'])]
    public function __invoke(
        Request $request,
        EntityManagerInterface $em,
        ValidatorInterface $validator
    ): JsonResponse {
        $payload = [];
        if (0 === strpos((string) $request->headers->get('Content-Type'), 'application/json')) {
            $payload = json_decode($request->getContent() ?? '', true) ?: [];
        }

        $get = fn(string $k, string $alt = '') => trim((string)($payload[$k] ?? $request->request->get($k, $alt)));

        $name  = $get('nom', $get('name', ''));
        $email = $get('email', '');
        $phone = $get('phone', '');
        $text  = $get('text', $get('message', ''));

        $msg = (new ContactMessage())
            ->setName($name)
            ->setEmail($email)
            ->setPhone($phone ?: null)
            ->setMessage($text);

        $errors = $validator->validate($msg);
        if (\count($errors) > 0) {
            return new JsonResponse([
                'ok' => false,
                'error' => (string) $errors[0]->getMessage(),
            ], 400);
        }

        $em->persist($msg);
        $em->flush();

        return new JsonResponse([
            'ok' => true,
            'id' => $msg->getId(),
            'createdAt' => $msg->getCreatedAt()?->format(\DateTimeInterface::ATOM),
        ], 201);
    }
}
