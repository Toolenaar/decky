export interface ElasticsearchConfig {
    node: string;
    auth?: {
        apiKey: string;
    } | {
        username: string;
        password: string;
    };
    indexName: string;
    maxRetries?: number;
    requestTimeout?: number;
    serverMode?: 'serverless' | 'traditional';
}
export declare function getElasticsearchConfig(): ElasticsearchConfig;
export declare function validateElasticsearchConfig(): void;
//# sourceMappingURL=config.d.ts.map