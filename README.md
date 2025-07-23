# Kubernetes Learning Curriculum

A comprehensive, hands-on curriculum to learn Kubernetes from zero to production-ready skills. This curriculum takes you from absolute beginner to confident Kubernetes practitioner through practical exercises, real-world projects, and systematic skill building.

## 🎯 What You'll Learn

By completing this curriculum, you'll be able to:
- **Deploy and manage** Kubernetes clusters confidently
- **Design production-ready architectures** using appropriate Kubernetes resources
- **Implement security best practices** and access controls
- **Handle persistent data** and stateful applications
- **Monitor, troubleshoot, and optimize** applications in production
- **Build complete CI/CD pipelines** with GitOps workflows

## 📚 Curriculum Overview

This curriculum is organized into **7 progressive modules**, each building on the previous ones. Each module includes theory, hands-on exercises, troubleshooting scenarios, and real-world projects.

```
┌─────────────────────────────────────────────────────────────┐
│                    Learning Journey                         │
│                                                             │
│  Module 1  →  Module 2  →  Module 3  →  Module 4          │
│  Basics       Pods        Services     Storage             │
│                                                             │
│           ↓                                                 │
│                                                             │
│  Module 5  →  Module 6  →  Module 7                       │
│  Workloads    Monitor     Production                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### [Module 1: Kubernetes Fundamentals](./Module-01-Kubernetes-Fundamentals/)
**Foundation concepts and basic resources**
- Containers vs VMs understanding
- Core Kubernetes architecture and components
- Basic resources: Pods, Deployments, Services, ConfigMaps
- Essential kubectl commands and workflow
- **Project**: Complete application deployment with all basic resources

### [Module 2: Pods and YAML Deep Dive](./Module-02-Pods-YAML-Deep-Dive/)
**Master pod concepts and YAML configuration**
- Pod anatomy: containers, volumes, networking
- Pod lifecycle states and transitions
- YAML structure mastery: metadata, spec, status
- Rolling updates and deployment strategies
- **Project**: Multi-tier microservices application with advanced pod patterns

### [Module 3: Services and Networking](./Module-03-Services-Networking/)
**Complete networking and service discovery**
- Kubernetes networking model (Cluster IP, Pod IP)
- Service types: ClusterIP, NodePort, LoadBalancer, ExternalName
- Ingress controllers and HTTP routing
- DNS and service discovery patterns
- **Project**: E-commerce platform networking architecture

### [Module 4: Storage and Configuration](./Module-04-Storage-Configuration/)
**Data persistence and configuration management**
- Volumes vs Persistent Volumes vs PVCs
- ConfigMaps and Secrets advanced patterns
- Storage Classes and dynamic provisioning
- Stateful applications and database management
- **Project**: Multi-tier SaaS platform with complete data strategy

### [Module 5: Advanced Workloads](./Module-05-Advanced-Workloads/)
**Master all workload types and container patterns**
- DaemonSets, StatefulSets, Jobs, CronJobs
- When to use each workload type
- Init containers and sidecar patterns
- Batch processing and scheduled tasks
- **Project**: Complete microservices platform with all workload types

### [Module 6: Observability and Debugging](./Module-06-Observability-Debugging/)
**Monitoring, logging, and troubleshooting**
- Centralized logging strategies
- Metrics collection and monitoring setup
- Health checks: liveness, readiness, startup probes
- Application debugging and performance optimization
- **Project**: Complete observability stack with monitoring and alerting

### [Module 7: Production and Security](./Module-07-Production-Security/)
**Production deployment and security hardening**
- Cluster components and control plane management
- Resource limits, requests, and cluster autoscaling
- RBAC and security policies
- GitOps and production deployment strategies
- **Final Project**: Production-ready multi-environment platform

## 🚀 Getting Started

### Prerequisites
- **Basic command line knowledge** (bash/terminal comfort)
- **Understanding of containerization** (Docker experience recommended)
- **Basic networking concepts** (ports, DNS, HTTP)
- **Text editor familiarity** (VS Code, vim, or similar)

### Setup Your Environment

1. **Install Required Tools**:
   ```bash
   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl && sudo mv kubectl /usr/local/bin/
   
   # Install Docker (for local development)
   # Follow: https://docs.docker.com/get-docker/
   
   # Install minikube (for local Kubernetes)
   curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
   sudo install minikube-linux-amd64 /usr/local/bin/minikube
   ```

2. **Choose Your Kubernetes Environment**:
   
   **Option A: Local Development (Recommended for Learning)**
   ```bash
   # Start minikube cluster
   minikube start --memory=4096 --cpus=2
   
   # Verify installation
   kubectl get nodes
   ```
   
   **Option B: Cloud Provider**
   - [Google GKE](https://cloud.google.com/kubernetes-engine)
   - [Amazon EKS](https://aws.amazon.com/eks/)
   - [Azure AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/)
   
   **Option C: Managed Kubernetes**
   - [DigitalOcean Kubernetes](https://www.digitalocean.com/products/kubernetes/)
   - [Linode LKE](https://www.linode.com/products/kubernetes/)

3. **Verify Your Setup**:
   ```bash
   kubectl version --client
   kubectl cluster-info
   kubectl get nodes
   ```

### Learning Path

**Start with Module 1** and progress sequentially. Each module builds on the previous ones:

```bash
# Clone this repository
git clone https://github.com/your-username/kubernetes-learning-curriculum.git
cd kubernetes-learning-curriculum

# Start with Module 1
cd Module-01-Kubernetes-Fundamentals
cat README.md
```

## 📖 How to Use This Curriculum

### Module Structure
Each module follows a consistent structure:

```
Module-XX-Topic-Name/
├── README.md                    # Complete learning guide
└── resources/
    ├── topic-examples/          # Organized YAML examples
    ├── exercises/               # Hands-on challenges
    └── projects/                # Real-world applications
```

### Learning Approach

1. **📖 Read the Theory**: Start with the README for conceptual understanding
2. **🛠️ Hands-On Practice**: Work through the exercises step-by-step
3. **🎯 Apply Knowledge**: Complete the module challenges
4. **🚀 Build Projects**: Implement the real-world projects
5. **❓ Test Understanding**: Answer the knowledge check questions
6. **🔍 Learn Troubleshooting**: Practice systematic debugging

### Exercise Types

- **🏃‍♂️ Quick Exercises**: 15-30 minutes, focused on specific concepts
- **🎯 Challenges**: 1-2 hours, integrate multiple concepts
- **🚀 Projects**: 4-8 hours, complete real-world applications
- **🔧 Troubleshooting**: Practice debugging broken scenarios

## 🎓 Skill Levels and Time Estimates

### Beginner (Modules 1-3)
**Time Estimate**: 4-6 weeks (5-10 hours/week)
- Fundamental concepts and basic operations
- Core resources and networking
- Simple deployments and troubleshooting

### Intermediate (Modules 4-5)  
**Time Estimate**: 3-4 weeks (8-12 hours/week)
- Advanced storage and configuration
- Multiple workload types
- Complex application architectures

### Advanced (Modules 6-7)
**Time Estimate**: 3-4 weeks (10-15 hours/week)
- Production operations and monitoring
- Security and best practices
- Complete platform deployment

**Total Curriculum Time**: 10-14 weeks (120-200 hours)

## 🛠️ Practical Learning Features

### Real-World Focus
- **Production-Ready Examples**: All examples include resource limits, health checks, and security considerations
- **Complete Applications**: Deploy full-stack applications, not just toy examples
- **Industry Patterns**: Learn patterns used in real production environments
- **Troubleshooting Skills**: Systematic approach to debugging common issues

### Hands-On Exercises
- **Progressive Complexity**: Start simple, build to complex scenarios
- **Immediate Feedback**: Every exercise has clear success criteria
- **Error Recovery**: Learn from common mistakes and failures
- **Best Practices**: Security, performance, and reliability built-in

### Projects and Challenges
- **WordPress Platform**: Complete CMS with database, storage, and networking
- **E-commerce Architecture**: Multi-tier application with microservices
- **Monitoring Stack**: Prometheus, Grafana, and alerting setup
- **CI/CD Pipeline**: GitOps workflow with automated deployments

## 🎯 Learning Outcomes by Module

| Module | Core Skills | Practical Abilities | Project Output |
|--------|-------------|---------------------|----------------|
| **1** | Basic Kubernetes concepts | Deploy simple applications | Multi-component web app |
| **2** | Pod management, YAML mastery | Complex deployments, updates | Microservices architecture |
| **3** | Networking, service discovery | Multi-tier communication | E-commerce platform networking |
| **4** | Storage, configuration | Stateful applications | SaaS platform data layer |
| **5** | All workload types | System services, batch jobs | Complete infrastructure platform |
| **6** | Monitoring, debugging | Production observability | Full monitoring stack |
| **7** | Security, production ops | Enterprise deployment | Production-ready platform |

## 🤝 Contributing

We welcome contributions to improve this curriculum! Here's how you can help:

### Types of Contributions
- **🐛 Bug Fixes**: Correct errors in exercises or documentation
- **📝 Content Improvements**: Enhance explanations or add examples
- **🆕 New Exercises**: Add additional practice scenarios
- **🔧 Tool Updates**: Update for new Kubernetes versions
- **🌍 Translations**: Help make content accessible in other languages

### How to Contribute
1. **Fork** this repository
2. **Create** a feature branch: `git checkout -b feature/new-exercise`
3. **Make** your changes with clear commit messages
4. **Test** your changes thoroughly
5. **Submit** a pull request with detailed description

### Contribution Guidelines
- Follow the existing module structure and formatting
- Include working YAML examples for all exercises
- Test all commands and procedures
- Update documentation for any changes
- Use clear, beginner-friendly explanations

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Command Line Comfort**: Can navigate directories, edit files, run commands
- [ ] **Docker Understanding**: Know what containers are and basic Docker commands
- [ ] **Networking Basics**: Understand IPs, ports, DNS, and HTTP
- [ ] **YAML Familiarity**: Can read and write basic YAML syntax
- [ ] **Development Environment**: Text editor, terminal, and command-line tools
- [ ] **Learning Time**: Committed 5-15 hours per week for 10-14 weeks
- [ ] **Practice Environment**: Access to Kubernetes cluster (local or cloud)

## 🆘 Getting Help

### When You're Stuck
1. **Read the Error Messages**: Kubernetes error messages are usually helpful
2. **Check the Troubleshooting Guides**: Each module has common issues and solutions
3. **Use kubectl describe**: Get detailed information about resource status
4. **Check the Logs**: `kubectl logs` often reveals the problem
5. **Verify Your YAML**: Use online validators or `kubectl --dry-run`

### Community Resources
- **Kubernetes Documentation**: [kubernetes.io/docs](https://kubernetes.io/docs/)
- **Kubernetes Slack**: [kubernetes.slack.com](https://kubernetes.slack.com/)
- **Stack Overflow**: Tag questions with `kubernetes`
- **Reddit**: [r/kubernetes](https://www.reddit.com/r/kubernetes/)
- **CNCF Community**: [community.cncf.io](https://community.cncf.io/)

### Course-Specific Help
- **GitHub Issues**: Report bugs or ask questions
- **Discussions**: Share your projects and get feedback
- **Wiki**: Additional resources and FAQs

## 🏆 Certification Path

This curriculum prepares you for:

### Kubernetes Certifications
- **CKAD** (Certified Kubernetes Application Developer): Modules 1-5 + practice
- **CKA** (Certified Kubernetes Administrator): Complete curriculum + admin topics
- **CKS** (Certified Kubernetes Security Specialist): Module 7 + additional security focus

### Career Preparation
- **DevOps Engineer**: Focus on Modules 5-7, CI/CD, and automation
- **Platform Engineer**: Emphasize infrastructure modules and multi-tenancy
- **Site Reliability Engineer**: Strong focus on monitoring, troubleshooting, and operations
- **Cloud Architect**: Understand all modules with focus on design patterns

## 📈 Success Metrics

Track your learning progress:

### Knowledge Milestones
- [ ] Can explain Kubernetes architecture and core concepts
- [ ] Can deploy applications using appropriate workload types
- [ ] Can design networking and service communication
- [ ] Can handle data persistence and configuration
- [ ] Can implement monitoring and troubleshooting
- [ ] Can deploy production-ready applications with security

### Practical Milestones
- [ ] Deploy a multi-tier application from scratch
- [ ] Debug and fix broken Kubernetes deployments
- [ ] Implement a complete CI/CD pipeline
- [ ] Set up monitoring and alerting for applications
- [ ] Secure a Kubernetes cluster following best practices
- [ ] Design and implement a production platform

## 📝 License

This curriculum is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

This curriculum was created with inspiration from:
- **Kubernetes Community**: For excellent documentation and best practices
- **CNCF Ecosystem**: For the amazing tools and technologies
- **Industry Practitioners**: Who shared their real-world experiences
- **Learning Community**: Students and instructors who provided feedback

---

## 🚀 Ready to Start?

Begin your Kubernetes journey with **[Module 1: Kubernetes Fundamentals](./Module-01-Kubernetes-Fundamentals/)**!

Remember: **Learning Kubernetes is a journey, not a destination**. Take your time, practice consistently, and don't hesitate to ask for help when you need it.
**Happy Learning! 🎉**
