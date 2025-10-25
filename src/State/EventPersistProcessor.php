<?php

namespace App\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Entity\Event;
use App\Repository\EventRepository;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

final class EventPersistProcessor implements ProcessorInterface
{
    public function __construct(
        #[Autowire(service: 'api_platform.doctrine.orm.state.persist_processor')]
        private ProcessorInterface $persistProcessor,
        private EventRepository $repo
    ) {}

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        if (!$data instanceof Event) {
            return $this->persistProcessor->process($data, $operation, $uriVariables, $context);
        }

        if ($data->getStart() >= $data->getEnd()) {
            throw new \InvalidArgumentException('La date de début doit être antérieure à la date de fin.');
        }

        $qb = $this->repo->createQueryBuilder('e')
            ->where('e.start < :end AND e.end > :start')
            ->setParameter('start', $data->getStart())
            ->setParameter('end', $data->getEnd())
            ->setMaxResults(1);

        if (null !== $data->getId()) {
            $qb->andWhere('e.id != :id')->setParameter('id', $data->getId());
        }

        $overlap = $qb->getQuery()->getOneOrNullResult();
        if ($overlap) {
            throw new ConflictHttpException('Créneau déjà occupé.');
        }

        if (null === $data->getCreatedAt()) {
            $data->setCreatedAt(new \DateTimeImmutable());
        }
        if (!$data->getStatus()) {
            $data->setStatus('pending');
        }

        return $this->persistProcessor->process($data, $operation, $uriVariables, $context);
    }
}
