/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.13-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: academia_jiujitsu
-- ------------------------------------------------------
-- Server version	10.11.13-MariaDB-ubu2204

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `alunos`
--

DROP TABLE IF EXISTS `alunos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `alunos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `data_nascimento` date DEFAULT NULL,
  `cor_faixa` varchar(50) DEFAULT NULL,
  `turma` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alunos`
--

LOCK TABLES `alunos` WRITE;
/*!40000 ALTER TABLE `alunos` DISABLE KEYS */;
INSERT INTO `alunos` VALUES
(1,'José Augusto','2005-08-09','Azul','Adultos'),
(5,'Davi Eduardo Accioly Nascimento Silva','2017-08-25','Cinza/Branca','Kids'),
(6,'Thomás Gonçalves da Silva ','2017-12-30','Branca','Kids'),
(7,'João Lucas da Trindade Santos','2015-08-06','Branca','Kids'),
(8,'Wesley Gabriel do Nascimento Silva','2017-05-31','Branca','Kids'),
(9,'Raylan Dantas Lima','2018-08-12','Branca','Kids'),
(10,'João Matheus de Melo Cardoso','2012-04-27','Amarela','Adolescentes/Juvenil'),
(11,'Thiago Bruno Rodrigues de França','2010-12-13','Branca','Adolescentes/Juvenil'),
(12,'Ester Alexsandra de Souza Matias','2011-09-17','Branca','Adolescentes/Juvenil'),
(13,'Luiz Henrique de Melo Cardoso','2013-08-13','Branca','Adolescentes/Juvenil'),
(14,'Mizael Patrício da Silva','2009-05-08','Branca','Adolescentes/Juvenil'),
(15,'Paulo Victor Gomes de Carvalho','2017-08-18','Cinza','Adolescentes/Juvenil'),
(16,'Maria Laura Xavier Cardoso ','2015-11-13','Amarela/Branca','Adolescentes/Juvenil'),
(17,'Enzo Gabriel Santos de Almeida','2016-04-01','Branca','Adolescentes/Juvenil'),
(18,'João Miguel Silva Nascimento','2016-05-16','Branca','Adolescentes/Juvenil'),
(19,'Estevão Marcelino do Nascimento','2015-03-18','Cinza','Adolescentes/Juvenil'),
(20,'Maria Clara Guedes de Medeiros','2011-06-22','Branca','Adolescentes/Juvenil'),
(21,'Anny Karolline Lourenço de Carvalho ','2007-07-08','Azul','Adolescentes/Juvenil'),
(22,'Benjamin da Silva Santos','2017-08-21','Cinza/Branca','Kids'),
(23,'Samuel Galvão Gomes','2009-09-24','Branca','Adolescentes/Juvenil'),
(24,'Alex Bruno Carvalho de Lima','2008-11-12','Azul','Adultos'),
(25,'Pedro Lucas Mendes de Carvalho','2014-02-13','Branca','Adultos'),
(26,'Fernando Danilo Gomes Galvão ','2004-01-15','Branca','Adultos'),
(27,'André Vinicius Cardoso de Lima','2011-07-29','Amarela','Adultos'),
(28,'Alef Matias Nascimento de Almeida ','2009-10-10','Verde','Adultos'),
(29,'Kauã Carvalho do Nascimento','2007-09-06','Azul','Adultos'),
(30,'Josimar Santos de Sales','1973-03-14','Roxa','Master/Sênior'),
(31,'Rayane Emanuelly do Nascimento ','2010-11-17','Amarela/Branca','Adolescentes/Juvenil'),
(32,'Anthony Lohan Gomes dos Santos','2018-05-12','Branca','Kids'),
(33,'Akillys Estevam Borba de Almeida','2017-05-24','Cinza','Kids'),
(34,'Nicole de Lima Freire','2018-05-14','Branca','Kids'),
(35,'Giovanna Lamartine Flor','2022-07-08','Branca','Kids 2 a 3 anos');
/*!40000 ALTER TABLE `alunos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assinaturas`
--

DROP TABLE IF EXISTS `assinaturas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `assinaturas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `aluno_id` int(11) NOT NULL,
  `plano_id` int(11) NOT NULL,
  `valor_mensalidade` decimal(10,2) NOT NULL,
  `status` varchar(50) DEFAULT 'ativa',
  PRIMARY KEY (`id`),
  KEY `aluno_id` (`aluno_id`),
  KEY `plano_id` (`plano_id`),
  CONSTRAINT `assinaturas_ibfk_1` FOREIGN KEY (`aluno_id`) REFERENCES `alunos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `assinaturas_ibfk_2` FOREIGN KEY (`plano_id`) REFERENCES `planos` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assinaturas`
--

LOCK TABLES `assinaturas` WRITE;
/*!40000 ALTER TABLE `assinaturas` DISABLE KEYS */;
INSERT INTO `assinaturas` VALUES
(1,1,1,70.00,'ativa'),
(5,5,1,70.00,'ativa'),
(6,6,1,70.00,'ativa'),
(7,7,1,70.00,'ativa'),
(8,8,1,70.00,'ativa'),
(9,9,1,70.00,'ativa'),
(10,10,1,70.00,'ativa'),
(11,11,1,70.00,'ativa'),
(12,12,1,70.00,'ativa'),
(13,13,1,70.00,'ativa'),
(14,14,1,70.00,'ativa'),
(15,15,1,70.00,'ativa'),
(16,16,1,70.00,'ativa'),
(17,17,1,70.00,'ativa'),
(18,18,1,70.00,'ativa'),
(19,19,1,70.00,'ativa'),
(20,20,1,70.00,'ativa'),
(21,21,1,70.00,'ativa'),
(22,22,1,70.00,'ativa'),
(23,23,1,70.00,'ativa'),
(24,24,1,70.00,'ativa'),
(25,25,1,70.00,'ativa'),
(26,26,1,70.00,'ativa'),
(27,27,1,70.00,'ativa'),
(28,28,1,70.00,'ativa'),
(29,29,1,70.00,'ativa'),
(30,30,1,70.00,'ativa'),
(31,31,1,70.00,'ativa'),
(32,32,1,70.00,'ativa'),
(33,33,1,70.00,'ativa'),
(34,34,1,70.00,'ativa'),
(35,35,1,70.00,'ativa');
/*!40000 ALTER TABLE `assinaturas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `graduacoes`
--

DROP TABLE IF EXISTS `graduacoes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `graduacoes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `aluno_id` int(11) NOT NULL,
  `faixa` varchar(50) NOT NULL,
  `data_graduacao` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `aluno_id` (`aluno_id`),
  CONSTRAINT `graduacoes_ibfk_1` FOREIGN KEY (`aluno_id`) REFERENCES `alunos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `graduacoes`
--

LOCK TABLES `graduacoes` WRITE;
/*!40000 ALTER TABLE `graduacoes` DISABLE KEYS */;
INSERT INTO `graduacoes` VALUES
(1,1,'Azul','2023-06-15'),
(2,1,'Roxa','2024-07-01');
/*!40000 ALTER TABLE `graduacoes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pagamentos`
--

DROP TABLE IF EXISTS `pagamentos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pagamentos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `assinatura_id` int(11) NOT NULL,
  `valor_pago` decimal(10,2) NOT NULL,
  `data_pagamento` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `assinatura_id` (`assinatura_id`),
  CONSTRAINT `pagamentos_ibfk_1` FOREIGN KEY (`assinatura_id`) REFERENCES `assinaturas` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pagamentos`
--

LOCK TABLES `pagamentos` WRITE;
/*!40000 ALTER TABLE `pagamentos` DISABLE KEYS */;
INSERT INTO `pagamentos` VALUES
(1,1,70.00,'2025-06-22');
/*!40000 ALTER TABLE `pagamentos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `planos`
--

DROP TABLE IF EXISTS `planos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `planos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `valor` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `planos`
--

LOCK TABLES `planos` WRITE;
/*!40000 ALTER TABLE `planos` DISABLE KEYS */;
INSERT INTO `planos` VALUES
(1,'Plano Padrão',70.00);
/*!40000 ALTER TABLE `planos` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-07-07 20:35:28
