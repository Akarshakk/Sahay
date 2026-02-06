import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';

interface LocationPayload {
  latitude: number;
  longitude: number;
}

/**
 * WebSocket Gateway for real-time features
 * 
 * Features:
 * - Real-time incident updates
 * - Live verification notifications
 * - Location-based room subscriptions
 */
@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: '/events',
})
export class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(EventsGateway.name);

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /**
   * Subscribe to location-based updates
   * Creates a "room" based on grid cell for nearby notifications
   */
  @SubscribeMessage('subscribeToLocation')
  handleLocationSubscription(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: LocationPayload,
  ) {
    // Create a grid cell ID (approximate 2km grid)
    const gridCellId = this.getGridCellId(data.latitude, data.longitude);

    client.join(gridCellId);
    this.logger.log(`Client ${client.id} joined room: ${gridCellId}`);

    return { event: 'subscribed', data: { room: gridCellId } };
  }

  /**
   * Subscribe to regional updates (e.g. "Mumbai Central", "Maharashtra")
   */
  @SubscribeMessage('subscribeToRegion')
  handleRegionSubscription(
    @ConnectedSocket() client: Socket,
    @MessageBody() region: string,
  ) {
    if (!region) return;

    // Sanitize region name to create room ID
    const room = `region_${region.toLowerCase().replace(/\s+/g, '_')}`;

    client.join(room);
    this.logger.log(`Client ${client.id} joined region room: ${room}`);

    return { event: 'subscribedToRegion', data: { room } };
  }

  /**
   * Broadcast emergency alert to specific region
   */
  broadcastToRegion(region: string, alert: any) {
    const room = `region_${region.toLowerCase().replace(/\s+/g, '_')}`;
    this.logger.log(`Broadcasting to room: ${room}`);

    this.server.to(room).emit('emergencyBroadcast', {
      type: 'EMERGENCY_BROADCAST',
      data: alert,
    });
  }

  /**
   * Broadcast new post to nearby users
   */
  broadcastNewPost(post: any, latitude: number, longitude: number) {
    const gridCellId = this.getGridCellId(latitude, longitude);

    this.server.to(gridCellId).emit('newPost', {
      type: 'NEW_POST',
      data: post,
    });

    // Also broadcast to adjacent cells
    const adjacentCells = this.getAdjacentCells(latitude, longitude);
    adjacentCells.forEach((cellId) => {
      this.server.to(cellId).emit('newPost', {
        type: 'NEW_POST',
        data: post,
      });
    });
  }

  /**
   * Broadcast post verification
   */
  broadcastVerification(postId: string, verificationCount: number) {
    this.server.emit('postVerified', {
      type: 'POST_VERIFIED',
      data: { postId, verificationCount },
    });
  }

  /**
   * Broadcast promotion to incident
   */
  broadcastPromotion(postId: string, incidentId: string) {
    this.server.emit('postPromoted', {
      type: 'POST_PROMOTED',
      data: { postId, incidentId },
    });
  }

  /**
   * Broadcast incident status update
   */
  broadcastIncidentUpdate(incident: any) {
    this.server.emit('incidentUpdate', {
      type: 'INCIDENT_UPDATE',
      data: incident,
    });
  }

  /**
   * Subscribe to SOS alerts within a radius
   */
  @SubscribeMessage('subscribeToSOS')
  handleSOSSubscription(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { latitude: number; longitude: number; radiusKm?: number },
  ) {
    const gridCellId = this.getGridCellId(data.latitude, data.longitude);
    const sosRoom = `sos_${gridCellId}`;
    
    client.join(sosRoom);
    client.join('sos_global'); // Also join global SOS room
    
    // Join adjacent cells for wider coverage
    const adjacentCells = this.getAdjacentCells(data.latitude, data.longitude);
    adjacentCells.forEach((cellId) => {
      client.join(`sos_${cellId}`);
    });
    
    this.logger.log(`Client ${client.id} subscribed to SOS alerts in room: ${sosRoom}`);
    
    return { event: 'subscribedToSOS', data: { room: sosRoom } };
  }

  /**
   * Broadcast new SOS alert to nearby users
   */
  broadcastNewSOS(sosLog: any) {
    const { latitude, longitude } = sosLog.location;
    const gridCellId = this.getGridCellId(latitude, longitude);
    
    // Broadcast to the grid cell and adjacent cells
    this.server.to(`sos_${gridCellId}`).emit('newSOS', {
      type: 'NEW_SOS',
      data: sosLog,
    });
    
    const adjacentCells = this.getAdjacentCells(latitude, longitude);
    adjacentCells.forEach((cellId) => {
      this.server.to(`sos_${cellId}`).emit('newSOS', {
        type: 'NEW_SOS',
        data: sosLog,
      });
    });
    
    // Also broadcast to global SOS room (for authorities)
    this.server.to('sos_global').emit('newSOS', {
      type: 'NEW_SOS',
      data: sosLog,
    });
    
    this.logger.log(`🚨 SOS Alert broadcasted: ${sosLog.id}`);
  }

  /**
   * Broadcast SOS status update (e.g., marked safe)
   */
  broadcastSOSUpdate(sosLog: any) {
    this.server.to('sos_global').emit('sosUpdated', {
      type: 'SOS_UPDATED',
      data: sosLog,
    });
    
    // Also broadcast to location-based rooms
    if (sosLog.location) {
      const { latitude, longitude } = sosLog.location;
      const gridCellId = this.getGridCellId(latitude, longitude);
      
      this.server.to(`sos_${gridCellId}`).emit('sosUpdated', {
        type: 'SOS_UPDATED',
        data: sosLog,
      });
    }
  }

  /**
   * Broadcast when SOS is resolved/user is safe
   */
  broadcastSOSResolved(sosLog: any) {
    this.server.to('sos_global').emit('sosResolved', {
      type: 'SOS_RESOLVED',
      data: sosLog,
    });
    
    if (sosLog.location) {
      const { latitude, longitude } = sosLog.location;
      const gridCellId = this.getGridCellId(latitude, longitude);
      
      this.server.to(`sos_${gridCellId}`).emit('sosResolved', {
        type: 'SOS_RESOLVED',
        data: sosLog,
      });
    }
    
    this.logger.log(`✅ SOS Resolved: ${sosLog.id}`);
  }

  /**
   * Create a grid cell ID for location-based rooms
   * Each cell is approximately 2km x 2km
   */
  private getGridCellId(latitude: number, longitude: number): string {
    // ~0.018 degrees ≈ 2km at equator
    const latCell = Math.floor(latitude / 0.018);
    const lngCell = Math.floor(longitude / 0.018);
    return `grid_${latCell}_${lngCell}`;
  }

  /**
   * Get adjacent grid cells for broader coverage
   */
  private getAdjacentCells(latitude: number, longitude: number): string[] {
    const latCell = Math.floor(latitude / 0.018);
    const lngCell = Math.floor(longitude / 0.018);

    const cells: string[] = [];
    for (let dLat = -1; dLat <= 1; dLat++) {
      for (let dLng = -1; dLng <= 1; dLng++) {
        if (dLat !== 0 || dLng !== 0) {
          cells.push(`grid_${latCell + dLat}_${lngCell + dLng}`);
        }
      }
    }
    return cells;
  }
}
