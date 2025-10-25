<?php

namespace App\Controller;

use App\Entity\ContactMessage;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\{Request, JsonResponse};
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Component\Validator\Validator\ValidatorInterface;

class ContactApiController
{
    #[Route('/api/message', name: 'api_contact_message', methods: ['POST'])]
    public function __invoke(
        Request $request,
        EntityManagerInterface $em,
        ValidatorInterface $validator
    ): JsonResponse {
        $name    = trim((string)$request->request->get('nom', $request->request->get('name', '')));
        $email   = trim((string)$request->request->get('email', ''));
        $phone   = trim((string)$request->request->get('phone', ''));
        $text    = trim((string)$request->request->get('text', $request->request->get('message', '')));

        $msg = new ContactMessage();
        $msg->setName($name);
        $msg->setEmail($email);
        $msg->setPhone($phone ?: null);
        $msg->setMessage($text);

        $errors = $validator->validate($msg);
        if (count($errors) > 0) {

            return new JsonResponse([
                'ok' => false,
                'error' => (string)$errors[0]->getMessage()
            ], 400);
        }

        $em->persist($msg);
        $em->flush();

        return new JsonResponse([
            'ok' => true,
            'id' => $msg->getId()
        ], 201);
    }
}
