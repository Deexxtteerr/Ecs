#!/bin/bash

# ECS Management Script - CLI commands for monitoring and management
# As requested by mentor - all operations via CLI

REGION="us-west-1"
CLUSTER_NAME="demo-ecs-cluster"
SERVICE_NAME="demo-ecs-service"

function show_help() {
    echo "🔧 ECS Management CLI Commands"
    echo ""
    echo "Usage: ./manage_ecs.sh [command]"
    echo ""
    echo "Commands:"
    echo "  status      - Show overall system status"
    echo "  tasks       - List running tasks"
    echo "  logs        - Show recent application logs"
    echo "  scale       - Show auto scaling configuration"
    echo "  health      - Check load balancer health"
    echo "  metrics     - Show CloudWatch metrics"
    echo "  endpoints   - Show all service endpoints"
    echo "  destroy     - Destroy all infrastructure"
    echo ""
}

function show_status() {
    echo "📊 ECS Service Status"
    echo "===================="
    aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}' \
        --output table
    
    echo ""
    echo "🏗️  ECS Cluster Status"
    echo "===================="
    aws ecs describe-clusters \
        --clusters $CLUSTER_NAME \
        --region $REGION \
        --query 'clusters[0].{Name:clusterName,Status:status,ActiveServices:activeServicesCount,RunningTasks:runningTasksCount,PendingTasks:pendingTasksCount}' \
        --output table
}

function show_tasks() {
    echo "📋 Running Tasks"
    echo "================"
    aws ecs list-tasks \
        --cluster $CLUSTER_NAME \
        --region $REGION \
        --query 'taskArns' \
        --output table
    
    echo ""
    echo "📝 Task Details"
    echo "==============="
    TASK_ARNS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --region $REGION --query 'taskArns' --output text)
    if [ ! -z "$TASK_ARNS" ]; then
        aws ecs describe-tasks \
            --cluster $CLUSTER_NAME \
            --tasks $TASK_ARNS \
            --region $REGION \
            --query 'tasks[].{TaskArn:taskArn,LastStatus:lastStatus,HealthStatus:healthStatus,CreatedAt:createdAt}' \
            --output table
    else
        echo "No running tasks found"
    fi
}

function show_logs() {
    echo "📜 Recent Application Logs"
    echo "=========================="
    aws logs describe-log-streams \
        --log-group-name "/ecs/demo-ecs-example" \
        --region $REGION \
        --order-by LastEventTime \
        --descending \
        --max-items 1 \
        --query 'logStreams[0].logStreamName' \
        --output text | xargs -I {} aws logs get-log-events \
        --log-group-name "/ecs/demo-ecs-example" \
        --log-stream-name {} \
        --region $REGION \
        --query 'events[-10:].{Time:timestamp,Message:message}' \
        --output table
}

function show_scaling() {
    echo "🔄 Auto Scaling Configuration"
    echo "============================="
    aws application-autoscaling describe-scalable-targets \
        --service-namespace ecs \
        --region $REGION \
        --query 'ScalableTargets[].{ResourceId:ResourceId,MinCapacity:MinCapacity,MaxCapacity:MaxCapacity,RoleArn:RoleArn}' \
        --output table
    
    echo ""
    echo "📈 Scaling Policies"
    echo "=================="
    aws application-autoscaling describe-scaling-policies \
        --service-namespace ecs \
        --region $REGION \
        --query 'ScalingPolicies[].{PolicyName:PolicyName,PolicyType:PolicyType,TargetValue:TargetTrackingScalingPolicyConfiguration.TargetValue}' \
        --output table
}

function show_health() {
    echo "🏥 Load Balancer Health"
    echo "======================"
    
    # Get target group ARN
    TG_ARN=$(aws elbv2 describe-target-groups \
        --names "ecs-target-group" \
        --region $REGION \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text)
    
    if [ "$TG_ARN" != "None" ]; then
        aws elbv2 describe-target-health \
            --target-group-arn $TG_ARN \
            --region $REGION \
            --query 'TargetHealthDescriptions[].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State,Description:TargetHealth.Description}' \
            --output table
    else
        echo "Target group not found"
    fi
    
    echo ""
    echo "⚖️  Load Balancer Status"
    echo "======================="
    aws elbv2 describe-load-balancers \
        --names "ecs-alb" \
        --region $REGION \
        --query 'LoadBalancers[0].{Name:LoadBalancerName,State:State.Code,DNS:DNSName,Scheme:Scheme}' \
        --output table
}

function show_metrics() {
    echo "📊 CloudWatch Metrics (Last 1 Hour)"
    echo "===================================="
    
    END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S")
    START_TIME=$(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%S")
    
    echo "🖥️  CPU Utilization:"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS \
        --metric-name CPUUtilization \
        --dimensions Name=ServiceName,Value=$SERVICE_NAME Name=ClusterName,Value=$CLUSTER_NAME \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --period 300 \
        --statistics Average \
        --region $REGION \
        --query 'Datapoints[].{Time:Timestamp,CPU:Average}' \
        --output table
    
    echo ""
    echo "💾 Memory Utilization:"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS \
        --metric-name MemoryUtilization \
        --dimensions Name=ServiceName,Value=$SERVICE_NAME Name=ClusterName,Value=$CLUSTER_NAME \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --period 300 \
        --statistics Average \
        --region $REGION \
        --query 'Datapoints[].{Time:Timestamp,Memory:Average}' \
        --output table
}

function show_endpoints() {
    echo "🌐 Service Endpoints"
    echo "==================="
    
    ALB_DNS=$(aws elbv2 describe-load-balancers \
        --names "ecs-alb" \
        --region $REGION \
        --query 'LoadBalancers[0].DNSName' \
        --output text)
    
    echo "Load Balancer URL: http://$ALB_DNS"
    echo "Health Check: http://$ALB_DNS/"
    echo "Custom Greeting: http://$ALB_DNS/greet/YourName"
    echo ""
    echo "🔍 Test connectivity:"
    echo "curl -I http://$ALB_DNS"
}

function destroy_infrastructure() {
    echo "⚠️  WARNING: This will destroy ALL infrastructure!"
    echo "This includes:"
    echo "  - Load Balancer"
    echo "  - ECS Service and Tasks"
    echo "  - VPC and all networking"
    echo "  - Auto Scaling configuration"
    echo "  - All 32 resources created"
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "🗑️  Destroying infrastructure..."
        terraform destroy -auto-approve
        echo "✅ All resources destroyed"
    else
        echo "❌ Destruction cancelled"
    fi
}

# Main script logic
case "$1" in
    status)
        show_status
        ;;
    tasks)
        show_tasks
        ;;
    logs)
        show_logs
        ;;
    scale)
        show_scaling
        ;;
    health)
        show_health
        ;;
    metrics)
        show_metrics
        ;;
    endpoints)
        show_endpoints
        ;;
    destroy)
        destroy_infrastructure
        ;;
    *)
        show_help
        ;;
esac
