export class CreateBroadcastDto {
    title: string;
    message: string;
    region: string;
    priority: 'Low' | 'Medium' | 'High' | 'Critical';
    authorId?: string;
}
