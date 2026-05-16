export declare class GodotConnection {
    private wss;
    private client;
    private port;
    private fixedPort;
    private basePort;
    private maxPort;
    private pendingRequests;
    private heartbeatTimer;
    private lastPongAt;
    constructor(port?: number, fixedPort?: boolean, options?: {
        basePort?: number;
        maxPort?: number;
    });
    /** Start WebSocket server, retrying on the next port if the first bind races. */
    connect(): Promise<void>;
    /** Try to bind a single WebSocketServer. Resolves once 'listening' fires, rejects on bind error. */
    private bindWebSocketServer;
    private attachConnectionHandler;
    disconnect(): void;
    isConnected(): boolean;
    getPort(): number;
    sendCommand(method: string, params?: Record<string, unknown>): Promise<unknown>;
    private handleMessage;
    private rejectAllPending;
    private startHeartbeat;
    private stopHeartbeat;
}
//# sourceMappingURL=godot-connection.d.ts.map