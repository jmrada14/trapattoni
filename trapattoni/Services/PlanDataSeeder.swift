import Foundation
import SwiftData

enum PlanDataSeeder {
    /// Seeds training sessions and plans if none exist.
    /// Uses content-based detection instead of UserDefaults to work properly with CloudKit sync.
    @MainActor
    static func seedIfNeeded(modelContext: ModelContext) async throws {
        // Check if prebuilt plans already exist (from local seed or CloudKit sync)
        let planDescriptor = FetchDescriptor<TrainingPlan>(
            predicate: #Predicate { $0.isPrebuilt }
        )
        let existingPlanCount = try modelContext.fetchCount(planDescriptor)

        // Skip seeding if prebuilt plans already exist
        guard existingPlanCount == 0 else {
            return
        }

        // Check if template sessions already exist
        let sessionDescriptor = FetchDescriptor<TrainingSession>(
            predicate: #Predicate { $0.isTemplate }
        )
        let existingSessionCount = try modelContext.fetchCount(sessionDescriptor)

        // Fetch exercises for building sessions
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exercises = try modelContext.fetch(exerciseDescriptor)

        guard !exercises.isEmpty else {
            print("No exercises available for seeding sessions")
            return
        }

        // Group exercises by category and training type
        let byCategory = Dictionary(grouping: exercises, by: \.category)
        let soloExercises = exercises.filter { $0.trainingType == .solo }

        // Only create sessions if none exist
        var sessions: [String: TrainingSession] = [:]
        if existingSessionCount == 0 {
            sessions = createStarterSessions(modelContext: modelContext, byCategory: byCategory, soloExercises: soloExercises)
        } else {
            // Use existing sessions for plan creation
            let existingSessions = try modelContext.fetch(sessionDescriptor)
            for session in existingSessions {
                let key = session.name.lowercased()
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "-", with: "")
                sessions[key] = session
            }
        }

        // Create prebuilt plans with sessions
        createPrebuiltPlans(modelContext: modelContext, sessions: sessions)

        try modelContext.save()
    }

    // MARK: - Starter Sessions (10+)

    private static func createStarterSessions(
        modelContext: ModelContext,
        byCategory: [ExerciseCategory: [Exercise]],
        soloExercises: [Exercise]
    ) -> [String: TrainingSession] {
        var sessions: [String: TrainingSession] = [:]

        // 1. Dynamic Warm-Up (5-10 min)
        let warmUp = TrainingSession(
            name: "starterSession.warmUp.name",
            description: "starterSession.warmUp.desc",
            templateType: .warmUp,
            defaultRestSeconds: 15,
            isTemplate: true
        )
        modelContext.insert(warmUp)
        if let fitness = byCategory[.fitnessConditioning] {
            for exercise in fitness.prefix(2) {
                warmUp.addExercise(exercise, durationSeconds: 180, restAfterSeconds: 15)
            }
        }
        sessions["warmUp"] = warmUp

        // 2. Ball Mastery Basics (15-20 min) - Beginner
        let ballMastery = TrainingSession(
            name: "starterSession.ballMastery.name",
            description: "starterSession.ballMastery.desc",
            templateType: .quickSession,
            defaultRestSeconds: 30,
            isTemplate: true
        )
        modelContext.insert(ballMastery)
        if let dribbling = byCategory[.dribbling]?.filter({ $0.skillLevel == .beginner }) {
            for exercise in dribbling.prefix(3) {
                ballMastery.addExercise(exercise, durationSeconds: 300, restAfterSeconds: 30)
            }
        }
        sessions["ballMastery"] = ballMastery

        // 3. Cone Dribbling Circuit (20 min) - Beginner/Intermediate
        let coneDribbling = TrainingSession(
            name: "starterSession.coneDribbling.name",
            description: "starterSession.coneDribbling.desc",
            templateType: .skillFocus,
            defaultRestSeconds: 30,
            isTemplate: true
        )
        modelContext.insert(coneDribbling)
        if let dribbling = byCategory[.dribbling] {
            for exercise in dribbling.prefix(4) {
                coneDribbling.addExercise(exercise, durationSeconds: 240, restAfterSeconds: 30)
            }
        }
        sessions["coneDribbling"] = coneDribbling

        // 4. Wall Passing Drills (15 min) - Solo Passing
        let wallPassing = TrainingSession(
            name: "starterSession.wallPassing.name",
            description: "starterSession.wallPassing.desc",
            templateType: .skillFocus,
            defaultRestSeconds: 20,
            isTemplate: true
        )
        modelContext.insert(wallPassing)
        if let passing = byCategory[.passing]?.filter({ $0.trainingType == .solo }) {
            for exercise in passing.prefix(3) {
                wallPassing.addExercise(exercise, durationSeconds: 300, restAfterSeconds: 20)
            }
        } else if let passing = byCategory[.passing] {
            for exercise in passing.prefix(3) {
                wallPassing.addExercise(exercise, durationSeconds: 300, restAfterSeconds: 20)
            }
        }
        sessions["wallPassing"] = wallPassing

        // 5. First Touch Foundation (20 min)
        let firstTouch = TrainingSession(
            name: "starterSession.firstTouch.name",
            description: "starterSession.firstTouch.desc",
            templateType: .skillFocus,
            defaultRestSeconds: 30,
            isTemplate: true
        )
        modelContext.insert(firstTouch)
        if let touch = byCategory[.firstTouch] {
            for exercise in touch.prefix(4) {
                firstTouch.addExercise(exercise, durationSeconds: 300, restAfterSeconds: 30)
            }
        }
        sessions["firstTouch"] = firstTouch

        // 6. Shooting Fundamentals (25 min) - Beginner Shooting
        let shootingBasics = TrainingSession(
            name: "starterSession.shootingBasics.name",
            description: "starterSession.shootingBasics.desc",
            templateType: .skillFocus,
            defaultRestSeconds: 45,
            isTemplate: true
        )
        modelContext.insert(shootingBasics)
        if let shooting = byCategory[.shooting]?.filter({ $0.skillLevel == .beginner || $0.skillLevel == .intermediate }) {
            for exercise in shooting.prefix(3) {
                shootingBasics.addExercise(exercise, durationSeconds: 420, restAfterSeconds: 45)
            }
        } else if let shooting = byCategory[.shooting] {
            for exercise in shooting.prefix(3) {
                shootingBasics.addExercise(exercise, durationSeconds: 420, restAfterSeconds: 45)
            }
        }
        sessions["shootingBasics"] = shootingBasics

        // 7. Speed & Agility Circuit (30 min) - Fitness
        let speedAgility = TrainingSession(
            name: "starterSession.speedAgility.name",
            description: "starterSession.speedAgility.desc",
            templateType: .fullWorkout,
            defaultRestSeconds: 45,
            isTemplate: true
        )
        modelContext.insert(speedAgility)
        if let fitness = byCategory[.fitnessConditioning] {
            for exercise in fitness.prefix(5) {
                speedAgility.addExercise(exercise, durationSeconds: 300, restAfterSeconds: 45)
            }
        }
        sessions["speedAgility"] = speedAgility

        // 8. Advanced Ball Control (25 min) - Intermediate/Advanced
        let advancedControl = TrainingSession(
            name: "starterSession.advancedControl.name",
            description: "starterSession.advancedControl.desc",
            templateType: .skillFocus,
            defaultRestSeconds: 30,
            isTemplate: true
        )
        modelContext.insert(advancedControl)
        if let dribbling = byCategory[.dribbling]?.filter({ $0.skillLevel == .intermediate || $0.skillLevel == .advanced }) {
            for exercise in dribbling.prefix(4) {
                advancedControl.addExercise(exercise, durationSeconds: 360, restAfterSeconds: 30)
            }
        } else if let dribbling = byCategory[.dribbling] {
            for exercise in dribbling.suffix(4) {
                advancedControl.addExercise(exercise, durationSeconds: 360, restAfterSeconds: 30)
            }
        }
        sessions["advancedControl"] = advancedControl

        // 9. Finishing From All Angles (30 min) - Advanced Shooting
        let advancedFinishing = TrainingSession(
            name: "starterSession.advancedFinishing.name",
            description: "starterSession.advancedFinishing.desc",
            templateType: .skillFocus,
            defaultRestSeconds: 60,
            isTemplate: true
        )
        modelContext.insert(advancedFinishing)
        if let shooting = byCategory[.shooting] {
            for exercise in shooting.prefix(4) {
                advancedFinishing.addExercise(exercise, durationSeconds: 420, restAfterSeconds: 60)
            }
        }
        sessions["advancedFinishing"] = advancedFinishing

        // 10. Complete Skills Workout (45 min) - Full Session
        let completeWorkout = TrainingSession(
            name: "starterSession.completeWorkout.name",
            description: "starterSession.completeWorkout.desc",
            templateType: .fullWorkout,
            defaultRestSeconds: 60,
            isTemplate: true
        )
        modelContext.insert(completeWorkout)
        let categories: [ExerciseCategory] = [.dribbling, .passing, .firstTouch, .shooting, .fitnessConditioning]
        for category in categories {
            if let exercise = byCategory[category]?.first {
                completeWorkout.addExercise(exercise, durationSeconds: 480, restAfterSeconds: 60)
            }
        }
        sessions["completeWorkout"] = completeWorkout

        // 11. Defending Fundamentals (20 min)
        let defending = TrainingSession(
            name: "starterSession.defending.name",
            description: "starterSession.defending.desc",
            templateType: .skillFocus,
            defaultRestSeconds: 30,
            isTemplate: true
        )
        modelContext.insert(defending)
        if let defendingEx = byCategory[.defending] {
            for exercise in defendingEx.prefix(4) {
                defending.addExercise(exercise, durationSeconds: 300, restAfterSeconds: 30)
            }
        }
        sessions["defending"] = defending

        // 12. Set Piece Specialist (25 min)
        let setPieces = TrainingSession(
            name: "starterSession.setPieces.name",
            description: "starterSession.setPieces.desc",
            templateType: .skillFocus,
            defaultRestSeconds: 45,
            isTemplate: true
        )
        modelContext.insert(setPieces)
        if let setPieceEx = byCategory[.setPieces] {
            for exercise in setPieceEx.prefix(4) {
                setPieces.addExercise(exercise, durationSeconds: 360, restAfterSeconds: 45)
            }
        }
        sessions["setPieces"] = setPieces

        // 13. Quick Touch Training (15 min) - Fast Session
        let quickTouch = TrainingSession(
            name: "starterSession.quickTouch.name",
            description: "starterSession.quickTouch.desc",
            templateType: .quickSession,
            defaultRestSeconds: 20,
            isTemplate: true
        )
        modelContext.insert(quickTouch)
        if let touch = byCategory[.firstTouch], let dribbling = byCategory[.dribbling] {
            if let ex1 = touch.first {
                quickTouch.addExercise(ex1, durationSeconds: 240, restAfterSeconds: 20)
            }
            if let ex2 = dribbling.first {
                quickTouch.addExercise(ex2, durationSeconds: 240, restAfterSeconds: 20)
            }
        }
        sessions["quickTouch"] = quickTouch

        // 14. Passing Combinations (20 min)
        let passingCombos = TrainingSession(
            name: "starterSession.passingCombos.name",
            description: "starterSession.passingCombos.desc",
            templateType: .skillFocus,
            defaultRestSeconds: 30,
            isTemplate: true
        )
        modelContext.insert(passingCombos)
        if let passing = byCategory[.passing] {
            for exercise in passing.prefix(4) {
                passingCombos.addExercise(exercise, durationSeconds: 300, restAfterSeconds: 30)
            }
        }
        sessions["passingCombos"] = passingCombos

        return sessions
    }

    // MARK: - Prebuilt Plans with Sessions

    private static func createPrebuiltPlans(modelContext: ModelContext, sessions: [String: TrainingSession]) {

        // ============================================
        // BEGINNER PLANS (2)
        // ============================================

        // PLAN 1: Beginner Fundamentals (4 weeks, 3x/week)
        let beginnerFundamentals = TrainingPlan(
            name: "starterPlan.beginnerFundamentals.name",
            description: "starterPlan.beginnerFundamentals.desc",
            durationWeeks: 4,
            targetSessionsPerWeek: 3,
            isPrebuilt: true
        )
        modelContext.insert(beginnerFundamentals)

        // Week 1
        addSession(sessions["warmUp"], to: beginnerFundamentals, week: 1, order: 1)
        addSession(sessions["ballMastery"], to: beginnerFundamentals, week: 1, order: 2)
        addSession(sessions["firstTouch"], to: beginnerFundamentals, week: 1, order: 3)
        // Week 2
        addSession(sessions["coneDribbling"], to: beginnerFundamentals, week: 2, order: 1)
        addSession(sessions["wallPassing"], to: beginnerFundamentals, week: 2, order: 2)
        addSession(sessions["ballMastery"], to: beginnerFundamentals, week: 2, order: 3)
        // Week 3
        addSession(sessions["firstTouch"], to: beginnerFundamentals, week: 3, order: 1)
        addSession(sessions["shootingBasics"], to: beginnerFundamentals, week: 3, order: 2)
        addSession(sessions["coneDribbling"], to: beginnerFundamentals, week: 3, order: 3)
        // Week 4
        addSession(sessions["passingCombos"], to: beginnerFundamentals, week: 4, order: 1)
        addSession(sessions["quickTouch"], to: beginnerFundamentals, week: 4, order: 2)
        addSession(sessions["completeWorkout"], to: beginnerFundamentals, week: 4, order: 3)

        // PLAN 2: Ball Control Basics (4 weeks, 3x/week)
        let ballControlBasics = TrainingPlan(
            name: "starterPlan.ballControlBasics.name",
            description: "starterPlan.ballControlBasics.desc",
            durationWeeks: 4,
            targetSessionsPerWeek: 3,
            isPrebuilt: true
        )
        modelContext.insert(ballControlBasics)

        // Week 1
        addSession(sessions["warmUp"], to: ballControlBasics, week: 1, order: 1)
        addSession(sessions["firstTouch"], to: ballControlBasics, week: 1, order: 2)
        addSession(sessions["ballMastery"], to: ballControlBasics, week: 1, order: 3)
        // Week 2
        addSession(sessions["quickTouch"], to: ballControlBasics, week: 2, order: 1)
        addSession(sessions["firstTouch"], to: ballControlBasics, week: 2, order: 2)
        addSession(sessions["coneDribbling"], to: ballControlBasics, week: 2, order: 3)
        // Week 3
        addSession(sessions["ballMastery"], to: ballControlBasics, week: 3, order: 1)
        addSession(sessions["wallPassing"], to: ballControlBasics, week: 3, order: 2)
        addSession(sessions["quickTouch"], to: ballControlBasics, week: 3, order: 3)
        // Week 4
        addSession(sessions["firstTouch"], to: ballControlBasics, week: 4, order: 1)
        addSession(sessions["coneDribbling"], to: ballControlBasics, week: 4, order: 2)
        addSession(sessions["ballMastery"], to: ballControlBasics, week: 4, order: 3)

        // ============================================
        // INTERMEDIATE PLANS (2)
        // ============================================

        // PLAN 3: Complete Skills Development (6 weeks, 4x/week)
        let completeSkills = TrainingPlan(
            name: "starterPlan.completeSkills.name",
            description: "starterPlan.completeSkills.desc",
            durationWeeks: 6,
            targetSessionsPerWeek: 4,
            isPrebuilt: true
        )
        modelContext.insert(completeSkills)

        // Week 1
        addSession(sessions["warmUp"], to: completeSkills, week: 1, order: 1)
        addSession(sessions["coneDribbling"], to: completeSkills, week: 1, order: 2)
        addSession(sessions["wallPassing"], to: completeSkills, week: 1, order: 3)
        addSession(sessions["firstTouch"], to: completeSkills, week: 1, order: 4)
        // Week 2
        addSession(sessions["ballMastery"], to: completeSkills, week: 2, order: 1)
        addSession(sessions["passingCombos"], to: completeSkills, week: 2, order: 2)
        addSession(sessions["shootingBasics"], to: completeSkills, week: 2, order: 3)
        addSession(sessions["speedAgility"], to: completeSkills, week: 2, order: 4)
        // Week 3
        addSession(sessions["advancedControl"], to: completeSkills, week: 3, order: 1)
        addSession(sessions["firstTouch"], to: completeSkills, week: 3, order: 2)
        addSession(sessions["defending"], to: completeSkills, week: 3, order: 3)
        addSession(sessions["quickTouch"], to: completeSkills, week: 3, order: 4)
        // Week 4
        addSession(sessions["coneDribbling"], to: completeSkills, week: 4, order: 1)
        addSession(sessions["advancedFinishing"], to: completeSkills, week: 4, order: 2)
        addSession(sessions["passingCombos"], to: completeSkills, week: 4, order: 3)
        addSession(sessions["speedAgility"], to: completeSkills, week: 4, order: 4)
        // Week 5
        addSession(sessions["advancedControl"], to: completeSkills, week: 5, order: 1)
        addSession(sessions["setPieces"], to: completeSkills, week: 5, order: 2)
        addSession(sessions["shootingBasics"], to: completeSkills, week: 5, order: 3)
        addSession(sessions["defending"], to: completeSkills, week: 5, order: 4)
        // Week 6
        addSession(sessions["completeWorkout"], to: completeSkills, week: 6, order: 1)
        addSession(sessions["advancedFinishing"], to: completeSkills, week: 6, order: 2)
        addSession(sessions["passingCombos"], to: completeSkills, week: 6, order: 3)
        addSession(sessions["completeWorkout"], to: completeSkills, week: 6, order: 4)

        // PLAN 4: Attacking Player Development (5 weeks, 3x/week)
        let attackingDev = TrainingPlan(
            name: "starterPlan.attackingDev.name",
            description: "starterPlan.attackingDev.desc",
            durationWeeks: 5,
            targetSessionsPerWeek: 3,
            isPrebuilt: true
        )
        modelContext.insert(attackingDev)

        // Week 1
        addSession(sessions["coneDribbling"], to: attackingDev, week: 1, order: 1)
        addSession(sessions["shootingBasics"], to: attackingDev, week: 1, order: 2)
        addSession(sessions["firstTouch"], to: attackingDev, week: 1, order: 3)
        // Week 2
        addSession(sessions["advancedControl"], to: attackingDev, week: 2, order: 1)
        addSession(sessions["advancedFinishing"], to: attackingDev, week: 2, order: 2)
        addSession(sessions["quickTouch"], to: attackingDev, week: 2, order: 3)
        // Week 3
        addSession(sessions["coneDribbling"], to: attackingDev, week: 3, order: 1)
        addSession(sessions["shootingBasics"], to: attackingDev, week: 3, order: 2)
        addSession(sessions["setPieces"], to: attackingDev, week: 3, order: 3)
        // Week 4
        addSession(sessions["advancedControl"], to: attackingDev, week: 4, order: 1)
        addSession(sessions["advancedFinishing"], to: attackingDev, week: 4, order: 2)
        addSession(sessions["speedAgility"], to: attackingDev, week: 4, order: 3)
        // Week 5
        addSession(sessions["completeWorkout"], to: attackingDev, week: 5, order: 1)
        addSession(sessions["advancedFinishing"], to: attackingDev, week: 5, order: 2)
        addSession(sessions["setPieces"], to: attackingDev, week: 5, order: 3)

        // ============================================
        // ADVANCED PLANS (2)
        // ============================================

        // PLAN 5: Elite Skills Mastery (6 weeks, 4x/week)
        let eliteSkills = TrainingPlan(
            name: "starterPlan.eliteSkills.name",
            description: "starterPlan.eliteSkills.desc",
            durationWeeks: 6,
            targetSessionsPerWeek: 4,
            isPrebuilt: true
        )
        modelContext.insert(eliteSkills)

        // Week 1
        addSession(sessions["advancedControl"], to: eliteSkills, week: 1, order: 1)
        addSession(sessions["passingCombos"], to: eliteSkills, week: 1, order: 2)
        addSession(sessions["advancedFinishing"], to: eliteSkills, week: 1, order: 3)
        addSession(sessions["speedAgility"], to: eliteSkills, week: 1, order: 4)
        // Week 2
        addSession(sessions["coneDribbling"], to: eliteSkills, week: 2, order: 1)
        addSession(sessions["setPieces"], to: eliteSkills, week: 2, order: 2)
        addSession(sessions["defending"], to: eliteSkills, week: 2, order: 3)
        addSession(sessions["quickTouch"], to: eliteSkills, week: 2, order: 4)
        // Week 3
        addSession(sessions["advancedControl"], to: eliteSkills, week: 3, order: 1)
        addSession(sessions["advancedFinishing"], to: eliteSkills, week: 3, order: 2)
        addSession(sessions["passingCombos"], to: eliteSkills, week: 3, order: 3)
        addSession(sessions["speedAgility"], to: eliteSkills, week: 3, order: 4)
        // Week 4
        addSession(sessions["completeWorkout"], to: eliteSkills, week: 4, order: 1)
        addSession(sessions["setPieces"], to: eliteSkills, week: 4, order: 2)
        addSession(sessions["advancedControl"], to: eliteSkills, week: 4, order: 3)
        addSession(sessions["defending"], to: eliteSkills, week: 4, order: 4)
        // Week 5
        addSession(sessions["advancedFinishing"], to: eliteSkills, week: 5, order: 1)
        addSession(sessions["coneDribbling"], to: eliteSkills, week: 5, order: 2)
        addSession(sessions["passingCombos"], to: eliteSkills, week: 5, order: 3)
        addSession(sessions["speedAgility"], to: eliteSkills, week: 5, order: 4)
        // Week 6
        addSession(sessions["completeWorkout"], to: eliteSkills, week: 6, order: 1)
        addSession(sessions["advancedControl"], to: eliteSkills, week: 6, order: 2)
        addSession(sessions["advancedFinishing"], to: eliteSkills, week: 6, order: 3)
        addSession(sessions["completeWorkout"], to: eliteSkills, week: 6, order: 4)

        // PLAN 6: Match Performance (4 weeks, 4x/week)
        let matchPerformance = TrainingPlan(
            name: "starterPlan.matchPerformance.name",
            description: "starterPlan.matchPerformance.desc",
            durationWeeks: 4,
            targetSessionsPerWeek: 4,
            isPrebuilt: true
        )
        modelContext.insert(matchPerformance)

        // Week 1
        addSession(sessions["speedAgility"], to: matchPerformance, week: 1, order: 1)
        addSession(sessions["passingCombos"], to: matchPerformance, week: 1, order: 2)
        addSession(sessions["advancedFinishing"], to: matchPerformance, week: 1, order: 3)
        addSession(sessions["defending"], to: matchPerformance, week: 1, order: 4)
        // Week 2
        addSession(sessions["advancedControl"], to: matchPerformance, week: 2, order: 1)
        addSession(sessions["setPieces"], to: matchPerformance, week: 2, order: 2)
        addSession(sessions["speedAgility"], to: matchPerformance, week: 2, order: 3)
        addSession(sessions["quickTouch"], to: matchPerformance, week: 2, order: 4)
        // Week 3
        addSession(sessions["coneDribbling"], to: matchPerformance, week: 3, order: 1)
        addSession(sessions["advancedFinishing"], to: matchPerformance, week: 3, order: 2)
        addSession(sessions["defending"], to: matchPerformance, week: 3, order: 3)
        addSession(sessions["speedAgility"], to: matchPerformance, week: 3, order: 4)
        // Week 4
        addSession(sessions["completeWorkout"], to: matchPerformance, week: 4, order: 1)
        addSession(sessions["setPieces"], to: matchPerformance, week: 4, order: 2)
        addSession(sessions["advancedControl"], to: matchPerformance, week: 4, order: 3)
        addSession(sessions["completeWorkout"], to: matchPerformance, week: 4, order: 4)

        // ============================================
        // FOCUSED FITNESS PLANS (2)
        // ============================================

        // PLAN 7: Speed & Agility Focus (6 weeks, 4x/week)
        let speedAgilityPlan = TrainingPlan(
            name: "starterPlan.speedAgility.name",
            description: "starterPlan.speedAgility.desc",
            durationWeeks: 6,
            targetSessionsPerWeek: 4,
            isPrebuilt: true
        )
        modelContext.insert(speedAgilityPlan)

        // Week 1
        addSession(sessions["warmUp"], to: speedAgilityPlan, week: 1, order: 1)
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 1, order: 2)
        addSession(sessions["quickTouch"], to: speedAgilityPlan, week: 1, order: 3)
        addSession(sessions["coneDribbling"], to: speedAgilityPlan, week: 1, order: 4)
        // Week 2
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 2, order: 1)
        addSession(sessions["ballMastery"], to: speedAgilityPlan, week: 2, order: 2)
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 2, order: 3)
        addSession(sessions["quickTouch"], to: speedAgilityPlan, week: 2, order: 4)
        // Week 3
        addSession(sessions["coneDribbling"], to: speedAgilityPlan, week: 3, order: 1)
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 3, order: 2)
        addSession(sessions["advancedControl"], to: speedAgilityPlan, week: 3, order: 3)
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 3, order: 4)
        // Week 4
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 4, order: 1)
        addSession(sessions["quickTouch"], to: speedAgilityPlan, week: 4, order: 2)
        addSession(sessions["coneDribbling"], to: speedAgilityPlan, week: 4, order: 3)
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 4, order: 4)
        // Week 5
        addSession(sessions["advancedControl"], to: speedAgilityPlan, week: 5, order: 1)
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 5, order: 2)
        addSession(sessions["ballMastery"], to: speedAgilityPlan, week: 5, order: 3)
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 5, order: 4)
        // Week 6
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 6, order: 1)
        addSession(sessions["coneDribbling"], to: speedAgilityPlan, week: 6, order: 2)
        addSession(sessions["speedAgility"], to: speedAgilityPlan, week: 6, order: 3)
        addSession(sessions["completeWorkout"], to: speedAgilityPlan, week: 6, order: 4)

        // PLAN 8: Strength & Conditioning (6 weeks, 3x/week)
        let strengthConditioning = TrainingPlan(
            name: "starterPlan.strengthConditioning.name",
            description: "starterPlan.strengthConditioning.desc",
            durationWeeks: 6,
            targetSessionsPerWeek: 3,
            isPrebuilt: true
        )
        modelContext.insert(strengthConditioning)

        // Week 1
        addSession(sessions["warmUp"], to: strengthConditioning, week: 1, order: 1)
        addSession(sessions["speedAgility"], to: strengthConditioning, week: 1, order: 2)
        addSession(sessions["ballMastery"], to: strengthConditioning, week: 1, order: 3)
        // Week 2
        addSession(sessions["speedAgility"], to: strengthConditioning, week: 2, order: 1)
        addSession(sessions["coneDribbling"], to: strengthConditioning, week: 2, order: 2)
        addSession(sessions["speedAgility"], to: strengthConditioning, week: 2, order: 3)
        // Week 3
        addSession(sessions["completeWorkout"], to: strengthConditioning, week: 3, order: 1)
        addSession(sessions["speedAgility"], to: strengthConditioning, week: 3, order: 2)
        addSession(sessions["quickTouch"], to: strengthConditioning, week: 3, order: 3)
        // Week 4
        addSession(sessions["speedAgility"], to: strengthConditioning, week: 4, order: 1)
        addSession(sessions["advancedControl"], to: strengthConditioning, week: 4, order: 2)
        addSession(sessions["speedAgility"], to: strengthConditioning, week: 4, order: 3)
        // Week 5
        addSession(sessions["completeWorkout"], to: strengthConditioning, week: 5, order: 1)
        addSession(sessions["speedAgility"], to: strengthConditioning, week: 5, order: 2)
        addSession(sessions["coneDribbling"], to: strengthConditioning, week: 5, order: 3)
        // Week 6
        addSession(sessions["speedAgility"], to: strengthConditioning, week: 6, order: 1)
        addSession(sessions["completeWorkout"], to: strengthConditioning, week: 6, order: 2)
        addSession(sessions["speedAgility"], to: strengthConditioning, week: 6, order: 3)
    }

    // Helper to add sessions more concisely
    private static func addSession(_ session: TrainingSession?, to plan: TrainingPlan, week: Int, order: Int) {
        if let session = session {
            plan.addSession(session, weekNumber: week, orderInWeek: order)
        }
    }
}
